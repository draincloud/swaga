require Logger

defmodule Script do
  @enforce_keys [
    :cmds
  ]
  defstruct [
    :cmds
  ]

  def add(%{cmds: cmds}, %{cmds: cmds_other}) when is_list(cmds) and is_list(cmds_other) do
    %Script{cmds: cmds ++ cmds_other}
  end

  def new(cmds) when is_list(cmds) do
    %Script{cmds: cmds}
  end

  def new() do
    %Script{cmds: []}
  end

  def parse(s) when is_binary(s) do
    {length, rest} = Tx.read_varint(s)
    cmds = []
    count = 0
    {rest_bin, parsed_cmds} = parse_script_commands(rest, cmds, count, length)
    {rest_bin, %Script{cmds: parsed_cmds}}
  end

  def parse(_) do
    raise "Type error s is not binary"
  end

  def parse_script_commands(<<current_byte, rest::binary>>, cmds, count, length)
      when count < length and current_byte >= 1 and current_byte <= 75 do
    <<cmd::binary-size(current_byte), rest_cmds::binary>> = rest
    parse_script_commands(rest_cmds, cmds ++ [cmd], count + 1 + current_byte, length)
  end

  def parse_script_commands(<<76, rest::binary>>, cmds, count, length)
      when count < length do
    <<first, rest2::binary>> = rest
    data_length = MathUtils.little_endian_to_int(<<first>>)
    <<cmd::binary-size(data_length), rest3::binary>> = rest2
    parse_script_commands(rest3, cmds ++ [cmd], count + data_length + 2, length)
  end

  def parse_script_commands(<<77, rest::binary>>, cmds, count, length)
      when count < length do
    count = count + 1
    <<first_two::binary-size(2), rest2::binary>> = rest
    data_length = MathUtils.little_endian_to_int(first_two)
    <<cmd::binary-size(data_length), rest3::binary>> = rest2
    parse_script_commands(rest3, cmds ++ [cmd], count + data_length + 3, length)
  end

  def parse_script_commands(<<op_code, rest::binary>>, cmds, count, length)
      when count < length and is_list(cmds) do
    parse_script_commands(rest, cmds ++ [op_code], count + 1, length)
  end

  def parse_script_commands(s, cmds, count, length) when count >= length do
    if count != length do
      raise "Script parsing failed: mismatched length (expected #{length}, got #{count})"
    end

    {s, cmds}
  end

  def parse_script_commands(_s, cmds, _count, _length) when not is_list(cmds) do
    raise "Cmds must be a list, received #{inspect(cmds)}"
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
        raise "Unsupported command: #{inspect(cmd)}"
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
    result = raw_serialize(script)
    Logger.debug("raw #{inspect(Base.encode16(result))}")
    total = result |> :binary.bin_to_list() |> length
    Tx.encode_varint(total) <> result
  end

  def raw_serialize(%{cmds: cmds}) do
    Enum.reduce(cmds, "", fn cmd, acc ->
      Logger.debug("cmd #{inspect(cmd)}")
      result = preprocess_command(cmd, acc)
      Logger.debug("105 RESULT #{inspect(Base.encode16(result))}")
      result
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

  defp iter_over_cmds([cmd | rest], stack, alt_stack, z) do
    case is_integer(cmd) do
      true ->
        operation = VM.fetch_operation(cmd)

        {:ok, new_stack} =
          cond do
            cmd in [99, 100] ->
              operation.(stack, rest)

            cmd in [107, 108] ->
              operation.(stack, alt_stack)

            cmd in [172, 173, 174, 175] ->
              operation.(stack, z)

            true ->
              operation.(stack)
          end

        iter_over_cmds(rest, new_stack, alt_stack, z)

      false ->
        new_stack = stack ++ [cmd]
        iter_over_cmds(rest, new_stack, alt_stack, z)
    end
  end

  # Takes a hash160 and returns the p2pkh ScriptPubKey
  # OP_DUP OP_HASH160 address OP_EQUALVERIFY OP_CHECKSIG
  def p2pkh_script(h160) do
    Script.new([0x76, 0xA9, h160, 0x88, 0xAC])
  end
end
