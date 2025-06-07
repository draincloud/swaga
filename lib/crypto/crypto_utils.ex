defmodule CryptoUtils do
  # Sha256 followed by ripemd160
  def hash160(s) do
    sha256_digest = :crypto.hash(:sha256, s)
    :crypto.hash(:ripemd160, sha256_digest)
  end

  # Two Rounds of sha256
  def double_hash256(data, output_type \\ :int) do
    # Compute SHA-256 hash
    # Convert the binary hash to an integer using big-endian
    data =
      data
      |> hash256()
      |> hash256()

    case output_type do
      :int -> data |> :binary.decode_unsigned(:big)
      :bin -> data
    end
  end

  def hash256(data, output_type \\ :bin) do
    case output_type do
      :int -> {:error, "Not supported"}
      :bin -> :crypto.hash(:sha256, data)
    end
  end

  def sha1(data) do
    :crypto.hash(:sha, data)
  end
end
