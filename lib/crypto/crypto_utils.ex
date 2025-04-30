defmodule CryptoUtils do
  # Sha256 followed by ripemd160
  def hash160(s) do
    sha256_digest = :crypto.hash(:sha256, s)
    ripemd160_digest = :crypto.hash(:ripemd160, sha256_digest)
    ripemd160_digest
  end

  # Two Rounds of sha256
  def double_hash256(data) do
    # Compute SHA-256 hash
    hash = hash_256(data)
    hash = hash_256(hash)
    # Convert the binary hash to an integer using big-endian
    :binary.decode_unsigned(hash, :big)
  end

  def hash_256(data) do
    :crypto.hash(:sha256, data)
  end

  def sha1(data) do
    :crypto.hash(:sha, data)
  end
end
