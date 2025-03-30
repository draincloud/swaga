defmodule CryptoUtils do
  def hash160(s) do
    sha256_digest = :crypto.hash(:sha256, s)
    ripemd160_digest = :crypto.hash(:ripemd160, sha256_digest)
    ripemd160_digest
  end

  def double_hash_to_int(data) do
    # Compute SHA-256 hash
    hash = :crypto.hash(:sha256, data)
    hash = :crypto.hash(:sha256, hash)
    # Convert the binary hash to an integer using big-endian
    :binary.decode_unsigned(hash, :big)
  end
end
