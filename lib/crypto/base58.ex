defmodule Base58 do
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

  def encode_num(num, result) when num > 0 do
    {num, mod} = div_mod(num, 58)

    encode_num(num, String.at(@base58_alphabet, mod) <> result)
  end

  def encode_num(_, result) do
    result
  end

  def encode_from_binary(binary) do
    zeros_len = count_zeros(binary)
    num = :binary.decode_unsigned(binary, :big)
    prefix = String.duplicate("1", zeros_len)
    result = ""
    encoded = encode_num(num, result)
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
end
