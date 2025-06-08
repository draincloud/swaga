defmodule Script do
  alias Helpers
  alias Transaction

  @enforce_keys [
    :cmds
  ]
  defstruct [
    :cmds
  ]

  @type t :: %__MODULE__{
          cmds: [binary()]
        }

  def add(%Script{cmds: cmds}, %Script{cmds: cmds_other})
      when is_list(cmds) and is_list(cmds_other) do
    %Script{cmds: cmds ++ cmds_other}
  end

  def new(cmds) when is_list(cmds) do
    %Script{cmds: cmds}
  end

  def new(), do: %Script{cmds: []}

  def parse(s) when is_binary(s) do
    {length, rest} = Transaction.read_varint(s)
    cmds = []
    count = 0

    case parse_script_commands(rest, cmds, count, length) do
      {:errro, reason} ->
        {:error, reason}

      {rest_bin, parsed_cmds} ->
        {rest_bin, %Script{cmds: parsed_cmds |> Enum.reverse()}}
    end
  end

  def parse(_) do
    {:error, :invalid_input_type}
  end

  def parse_script_commands(<<current_byte, rest::binary>>, cmds, count, length)
      when count < length and current_byte >= 1 and current_byte <= 75 do
    <<cmd::binary-size(current_byte), rest_cmds::binary>> = rest
    parse_script_commands(rest_cmds, [cmd | cmds], count + 1 + current_byte, length)
  end

  def parse_script_commands(<<76, rest::binary>>, cmds, count, length)
      when count < length do
    <<first, rest2::binary>> = rest
    data_length = MathUtils.little_endian_to_int(<<first>>)
    <<cmd::binary-size(data_length), rest3::binary>> = rest2
    parse_script_commands(rest3, [cmd | cmds], count + data_length + 2, length)
  end

  def parse_script_commands(<<77, rest::binary>>, cmds, count, length)
      when count < length do
    <<first_two::binary-size(2), rest2::binary>> = rest
    data_length = MathUtils.little_endian_to_int(first_two)
    <<cmd::binary-size(data_length), rest3::binary>> = rest2
    parse_script_commands(rest3, [cmd | cmds], count + 1 + data_length + 3, length)
  end

  def parse_script_commands(<<op_code, rest::binary>>, cmds, count, length)
      when count < length and is_list(cmds) do
    parse_script_commands(rest, [op_code | cmds], count + 1, length)
  end

  def parse_script_commands(s, cmds, count, length) when count >= length do
    if count != length do
      {:error, "Script parsing failed: mismatched length (expected #{length}, got #{count})"}
    end

    {s, cmds}
  end

  def parse_script_commands(_s, cmds, _count, _length) when not is_list(cmds) do
    {:error, "Cmds must be a list, received #{inspect(cmds)}"}
  end

  def preprocess_command(cmd, acc) do
    cond do
      is_integer(cmd) ->
        acc <> MathUtils.int_to_little_endian(cmd, 1)

      is_binary(cmd) and Helpers.is_hex_string?(cmd) ->
        serialize_script_cmd(Base.decode16!(cmd, case: :mixed), acc)

      is_binary(cmd) ->
        serialize_script_cmd(cmd, acc)

      true ->
        {:error, "Unsupported command: #{inspect(cmd)}"}
    end
  end

  def serialize_script_cmd(cmd, acc) when byte_size(cmd) < 75 do
    acc <> MathUtils.int_to_little_endian(byte_size(cmd), 1) <> cmd
  end

  def serialize_script_cmd(cmd, acc) when byte_size(cmd) > 75 and byte_size(cmd) < 0x100 do
    acc <>
      MathUtils.int_to_little_endian(76, 1) <>
      MathUtils.int_to_little_endian(byte_size(cmd), 1) <> cmd
  end

  def serialize_script_cmd(cmd, acc) when byte_size(cmd) >= 0x100 and byte_size(cmd) <= 520 do
    acc <>
      MathUtils.int_to_little_endian(77, 1) <>
      MathUtils.int_to_little_endian(byte_size(cmd), 2) <>
      cmd
  end

  def serialize_script_cmd(_, _) do
    raise "Too long an cmd"
  end

  def serialize(%Script{} = script) do
    serialized_script = raw_serialize(script)
    Transaction.encode_varint(byte_size(serialized_script)) <> serialized_script
  end

  def raw_serialize(%{cmds: cmds}) do
    Enum.reduce(cmds, "", fn cmd, acc ->
      preprocess_command(cmd, acc)
    end)
  end

  def evaluate(%Script{cmds: cmds}, z) do
    stack = []
    alt_stack = []
    {:ok} = iter_over_cmds(cmds, stack, alt_stack, z)
  end

  defp iter_over_cmds([], _, _, _) do
    {:ok}
  end

  defp iter_over_cmds([cmd | rest_cmds], stack, alt_stack, z) do
    case is_integer(cmd) do
      true ->
        operation = VM.fetch_operation(cmd)

        {:ok, new_stack} =
          cond do
            # OP_IF, OP_NOTIF requires the cmds array
            cmd in [99, 100] ->
              operation.(stack, rest_cmds)

            # OP_TOALTSTACK/OP_FROMALTSTACK requies the altstack
            cmd in [107, 108] ->
              operation.(stack, alt_stack)

            # These are signing operations, they need a sig_hash to check
            cmd in [172, 173, 174, 175] ->
              operation.(stack, z)

            true ->
              operation.(stack)
          end

        iter_over_cmds(rest_cmds, new_stack, alt_stack, z)

      false ->
        new_stack = stack ++ [cmd]

        case length(rest_cmds) == 3 do
          true ->
            [cmd1, cmd2 | _] = rest_cmds
            # PayToScriptHash implementation
            # 0xa9 -> OP_HASH160, 0x87 -> OP_EQUAL
            if cmd == 0xA9 and is_binary(cmd1) and
                 length(cmd1) == 20 and cmd2 == 0x87 do
              {rest_cmds, updated_stack} = VM.Script.P2SH.execute(cmd, rest_cmds, stack)
              iter_over_cmds(rest_cmds, updated_stack, alt_stack, z)
            else
              iter_over_cmds(rest_cmds, new_stack, alt_stack, z)
            end

          false ->
            iter_over_cmds(rest_cmds, new_stack, alt_stack, z)
        end
    end
  end

  # Takes a hash160 and returns the p2pkh ScriptPubKey
  # OP_DUP OP_HASH160 address OP_EQUALVERIFY OP_CHECKSIG
  def p2pkh_script(public_key_hash) when is_binary(public_key_hash) do
    public_key_hash =
      case Helpers.is_hex_string?(public_key_hash) do
        true -> public_key_hash |> Base.decode16!(case: :mixed)
        false -> public_key_hash
      end

    Script.new([0x76, 0xA9, public_key_hash, 0x88, 0xAC])
  end

  # Pay to witness public key hash
  # Same as Pay to Public Key Hash
  def p2wpkh(public_key_hash) when is_binary(public_key_hash) and byte_size(public_key_hash) do
    public_key_hash =
      case Helpers.is_hex_string?(public_key_hash) do
        true -> public_key_hash |> Base.decode16!(case: :mixed)
        false -> public_key_hash
      end

    Script.new([0x00, public_key_hash])
  end

  # Takes a byte sequence hash160 and returns a p2pkh address string
  def h160_to_p2pkh_address(hash, testnet \\ false) do
    # p2pkh has a prefix of b'\x00' for mainnet, b'\x6f' for testnet
    prefix =
      if testnet do
        <<0x6F>>
      else
        <<0x00>>
      end

    Base58.encode_base58_checksum(prefix <> hash)
  end

  # Takes a byte sequence hash160 and returns a p2sh address string
  def h160_to_p2sh_address(hash, testnet \\ false) do
    # p2sh has a prefix of 0x05 for mainnet, 0xc4 for testnet
    prefix =
      if testnet do
        <<0xC4>>
      else
        <<0x05>>
      end

    Base58.encode_base58_checksum(prefix <> hash)
  end

  # Segwit v1 (Taproot/P2TR) 34 bytes length
  def identify_script_type(<<0x51, 0x20, _::binary-size(32)>>) do
    :p2tr
  end

  # Segwit v0 P2WPKH
  def identify_script_type(<<0x00, 0x14, _::binary-size(20)>>) do
    :p2wpkh
  end

  # Segwit v0 P2PWSH
  def identify_script_type(<<0x00, 0x20, _::binary-size(32)>>) do
    :p2wsh
  end

  # P2SH
  def identify_script_type(<<0xA9, _::binary-size(22)>> = decoded_script) do
    # Last byte is `OP_EQUAL`
    <<0x87, _::binary>> = Binary.Common.reverse_binary(decoded_script)
    :p2sh
  end

  # p2pkh
  def identify_script_type(<<0x76, 0xA9, _::binary-size(22)>> = decoded_script) do
    # Last bytes are `OP_CHECKSIG`, `OP_EQUALVERIFY`
    <<0x76, 0x88, _::binary>> = Binary.Common.reverse_binary(decoded_script)
    :p2pkh
  end

  # p2pk
  def identify_script_type(<<0x21, _::binary-size(34)>> = decoded_script) do
    <<0xAC, _::binary>> = Binary.Common.reverse_binary(decoded_script)
    :p2pk
  end

  # p2pk
  def identify_script_type(<<0x41, _::binary-size(66)>> = decoded_script) do
    <<0xAC, _::binary>> = Binary.Common.reverse_binary(decoded_script)
    :p2pk
  end
end
