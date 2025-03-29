defmodule CryptoUtils do
  def hash160(s) do
    sha256_digest = :crypto.hash(:sha256, s)
    ripemd160_digest = :crypto.hash(:ripemd160, sha256_digest)
    ripemd160_digest
  end
end
