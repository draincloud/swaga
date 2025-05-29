defmodule NetworkEnvelope do
  require IEx

  @enforce_keys [
    :command,
    :payload,
    :magic
  ]

  defstruct [
    :command,
    :payload,
    :magic
  ]

  @network_magic <<0xF9, 0xBE, 0xB4, 0xD9>>
  @testnet_network_magic <<0x0B, 0x11, 0x09, 0x07>>

  def new(command, payload, testnet \\ false) do
    magic_bytes =
      if testnet do
        @testnet_network_magic
      else
        @network_magic
      end

    %NetworkEnvelope{
      command: command,
      payload: payload,
      magic: magic_bytes
    }
  end

  def debug(network) do
    ascii_command = :binary.first(network.command)
    Integer.to_string(ascii_command, 10) <> " : " <> Base.encode16(network.payload)
  end

  def check_network_magic(expected, expected) do
    :ok
  end

  def check_network_magic(expected, wrong) when expected != wrong do
    :error
  end

  def check_payload_size(payload_size, payload) do
    if payload_size > byte_size(payload) do
      :incorrect_payload_size
    else
      :ok
    end
  end

  def check_hash_sum(incorrect_payload_checksum, first4bytes)
      when incorrect_payload_checksum != first4bytes do
    :error
  end

  def check_hash_sum(payload_checksum, payload_checksum) do
    :ok
  end

  def parse(serialized_network, testnet \\ false)

  def parse("", _) do
    raise "Serialized envelope is empty, try retrying"
  end

  def parse(serialized_network, testnet) when is_binary(serialized_network) do
    expected_magic =
      if testnet do
        <<0x0B, 0x11, 0x09, 0x07>>
      else
        <<0xF9, 0xBE, 0xB4, 0xD9>>
      end

    <<network_magic::binary-size(4), command::binary-size(12), payload_length::binary-size(4),
      payload_checksum::binary-size(4), payload::binary>> = serialized_network

    :ok =
      case check_network_magic(expected_magic, network_magic) do
        :ok ->
          :ok

        :error ->
          raise "Magic is not right for expected #{inspect(expected_magic)}, got #{inspect(network_magic)}}"
      end

    payload_size = payload_length |> MathUtils.little_endian_to_int()

    case check_payload_size(payload_size, payload) do
      :ok ->
        <<payload_to_read::binary-size(payload_size), rest::binary>> =
          payload

        <<first4bytes::binary-size(4), _::binary>> =
          CryptoUtils.double_hash256(payload_to_read)
          |> :binary.encode_unsigned(:big)
          |> Helpers.pad_binary(32)

        :ok =
          case check_hash_sum(payload_checksum, first4bytes) do
            :ok ->
              :ok

            :error ->
              raise "Checksum is not equal to first 4 bytes of hash, expected(#{inspect(payload_checksum)}), received #{inspect(first4bytes)}"
          end

        {%NetworkEnvelope{
           command: String.trim(command) |> String.trim("\0"),
           payload: payload_to_read,
           magic: network_magic
         }, rest}

      :incorrect_payload_size ->
        {:missing_payload_size, serialized_network}
    end
  end

  def serialize(%NetworkEnvelope{
        command: command,
        payload: payload,
        magic: magic_bytes
      }) do
    payload_length = MathUtils.int_to_little_endian(byte_size(payload), 4)

    <<checksum::binary-size(4), _::binary>> =
      CryptoUtils.double_hash256(payload) |> :binary.encode_unsigned(:big)

    # Ensure it's 12 bytes, padded with null bytes (0x00)
    padded_command =
      command <> :binary.copy(<<0>>, 12 - byte_size(command))

    magic_bytes <> padded_command <> payload_length <> checksum <> payload
  end
end
