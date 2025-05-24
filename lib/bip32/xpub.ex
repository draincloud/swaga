defmodule BIP32.Xpub do
  require IEx

  @enforce_keys [
    :chain_code,
    :depth,
    :child_number,
    :parent_fingerprint,
    :public_key
  ]
  defstruct [
    :chain_code,
    # depth in HD tree (0 for master)
    :depth,
    # child index (0 for master)
    :child_number,
    # first 4 bytes of parent pubkey hash160
    :parent_fingerprint,
    # a compressed point on secp256k1
    :public_key
  ]

  def from_xpriv(secret, chain_code) when is_integer(secret) and is_binary(chain_code) do
    g = Secp256Point.get_g()
    pubkey_point = Secp256Point.mul(g, secret)
    compressed_pubkey = Secp256Point.compressed_sec(pubkey_point) |> Helpers.pad_binary(33)
    # For mainnet
    version_bytes = 0x0488B21E |> :binary.encode_unsigned(:big)

    parent_fingerprint =
      0x00000000 |> :binary.encode_unsigned(:big) |> Helpers.pad_binary(4)

    child_number = 0x00000000 |> :binary.encode_unsigned(:big) |> Helpers.pad_binary(4)
    # Check for byte_sizes
    4 = byte_size(version_bytes)
    4 = byte_size(parent_fingerprint)
    4 = byte_size(child_number)
    # those are binary values
    32 = byte_size(chain_code)
    33 = byte_size(compressed_pubkey)

    concat_bin =
      version_bytes <>
        <<0>> <> parent_fingerprint <> child_number <> chain_code <> compressed_pubkey

    <<checksum::binary-size(4), _::binary>> =
      concat_bin |> CryptoUtils.hash256() |> CryptoUtils.hash256()

    IEx.pry()

    %__MODULE__{
      chain_code: chain_code,
      public_key: (concat_bin <> checksum) |> Base58.encode_from_binary(),
      depth: 0,
      child_number: child_number,
      parent_fingerprint: parent_fingerprint
    }
  end
end
