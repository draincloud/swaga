defmodule Base58 do
  require IEx
  @base58_alphabet "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"

  def div_mod(a, b) do
    {div(a, b), rem(a, b)}
  end

  def count_zeros(bin) when is_binary(bin) do
    case bin do
      <<0, rest::binary>> -> 1 + count_zeros(rest)
      <<_::binary>> -> 0
    end
  end

  def encode_num(num, acc \\ []) when num > 0 do
    {num, mod} = div_mod(num, 58)

    encode_num(num, [String.at(@base58_alphabet, mod) | acc])
  end

  def encode_num(_, acc) do
    Enum.join(acc)
  end

  def encode_from_binary(binary) do
    zeros_len = count_zeros(binary)
    num = :binary.decode_unsigned(binary, :big)
    prefix = String.duplicate("1", zeros_len)
    encoded = encode_num(num)
    prefix <> encoded
  end

  def get_first_4_bytes_of_hash256(hash) do
    <<prefix::binary-size(4), _>> = hash
    prefix
  end

  def encode_base58_checksum(b) do
    double_hash = :crypto.hash(:sha256, :crypto.hash(:sha256, b))
    checksum = binary_part(double_hash, 0, 4)
    b = b <> checksum
    encode_from_binary(b)
  end

  # Take an address and get the 20-byte hash out of it. Opposite of encoding address
  def decode(s) do
    num =
      s
      |> String.graphemes()
      |> Enum.reduce(0, fn c, acc ->
        acc = acc * 58
        {index, _} = :binary.match(@base58_alphabet, c)
        acc + index
      end)

    combined = :binary.encode_unsigned(num, :big)

    # Ensure that the length is 25
    padded_combined =
      :binary.copy(<<0>>, 25 - byte_size(combined)) <> combined

    <<payload::binary-size(byte_size(padded_combined) - 4), checksum::binary-size(4)>> =
      padded_combined

    <<first_4_bytes::binary-size(4), _::binary>> =
      CryptoUtils.double_hash256(payload)
      |> :binary.encode_unsigned(:big)
      |> Helpers.pad_binary(byte_size(payload))

    if first_4_bytes != checksum do
      raise "bad address, checksum is incorrect"
    else
      # First byte is the network prefix, the middle 20 are actual address
      <<_first_byte::binary-size(1), result::binary-size(20), _checksum::binary-size(4)>> =
        padded_combined

      Base.encode16(result, case: :lower)
    end
  end
end
