defmodule MathUtils do
  # Calculates (n ^ k) % m.
  def powmod(n, k, m), do: powmod(n, k, m, 1)
  def powmod(_, 0, _, r), do: r

  def powmod(n, k, m, r) do
    r = if rem(k, 2) == 1, do: rem(r * n, m), else: r
    n = rem(n * n, m)
    k = div(k, 2)
    powmod(n, k, m, r)
  end

  def little_endian_to_int(binary_data) when is_binary(binary_data) do
    :binary.decode_unsigned(binary_data, :little)
  end

  def int_to_little_endian(num, length) do
    bin = :binary.encode_unsigned(num, :little)
    bin_len = bit_size(bin)
    length = length * 8

    if bin_len < length do
      <<0::size(length - bin_len)>> <> bin
    else
      bin
    end
  end
end
