require Logger

defmodule NetworkEnvelope do
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

  def parse(serialized_network, testnet \\ false) when is_binary(serialized_network) do
    expected_magic =
      if testnet do
        <<0x0B, 0x11, 0x09, 0x07>>
      else
        <<0xF9, 0xBE, 0xB4, 0xD9>>
      end

    <<network_magic::binary-size(4), command::binary-size(12), payload_length::binary-size(4),
      payload_checksum::binary-size(4), payload::binary>> = serialized_network

    payload_size = payload_length |> MathUtils.little_endian_to_int()

    <<payload_to_read::binary-size(payload_size), _::binary>> =
      payload

    if expected_magic == network_magic do
      <<first4bytes::binary-size(4), _::binary>> =
        CryptoUtils.double_hash256(payload_to_read) |> :binary.encode_unsigned(:big)

      if payload_checksum == first4bytes do
        %NetworkEnvelope{
          command: String.trim(command) |> String.trim("\0"),
          payload: payload_to_read,
          magic: network_magic
        }
      else
        raise "Checksum is not equal to first 4 bytes of hash"
      end
    else
      raise "Magic is not right for expected #{inspect(expected_magic)}, got #{inspect(network_magic)}"
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
