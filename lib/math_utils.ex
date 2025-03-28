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

  def hash_to_int(data) do
    # Compute SHA-256 hash
    hash = :crypto.hash(:sha256, data)
    hash = :crypto.hash(:sha256, hash)
    # Convert the binary hash to an integer using big-endian
    :binary.decode_unsigned(hash, :big)
  end
end
