defmodule BIP32.Xpub do
  require IEx
  @mainnet_xpub_version 0x0488B21E
  @enforce_keys [
    :chain_code,
    :depth,
    :child_number,
    :parent_fingerprint,
    :public_key,
    :encoded_xpub
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
    :public_key,
    # encoded public key
    :encoded_xpub
  ]

  def from_xprv(%{private_key: secret} = xprv) when is_binary(secret) do
    from_xprv(%{xprv | private_key: secret |> :binary.decode_unsigned(:big)})
  end

  def from_xprv(%{
        private_key: secret,
        parent_fingerprint: parent_fingerprint,
        child_number: child_number,
        chain_code: chain_code,
        depth: depth
      })
      when is_integer(secret) and is_binary(chain_code) do
    g = Secp256Point.get_g()
    pubkey_point = Secp256Point.mul(g, secret)
    compressed_pubkey = Secp256Point.compressed_sec(pubkey_point)
    # For mainnet
    version_bytes = @mainnet_xpub_version |> :binary.encode_unsigned(:big)

    parent_fingerprint =
      parent_fingerprint |> :binary.encode_unsigned(:big) |> Helpers.pad_binary(4)

    child_number = child_number |> :binary.encode_unsigned(:big) |> Helpers.pad_binary(4)
    # Check for byte_sizes
    4 = byte_size(version_bytes)
    4 = byte_size(parent_fingerprint)
    4 = byte_size(child_number)
    # those are binary values
    32 = byte_size(chain_code)
    ext_pubkey = compressed_pubkey |> Helpers.pad_binary(33)
    33 = byte_size(ext_pubkey)

    concat_bin =
      version_bytes <>
        <<depth>> <> parent_fingerprint <> child_number <> chain_code <> ext_pubkey

    <<checksum::binary-size(4), _::binary>> =
      concat_bin |> CryptoUtils.hash256() |> CryptoUtils.hash256()

    %__MODULE__{
      chain_code: chain_code,
      public_key: compressed_pubkey,
      encoded_xpub: (concat_bin <> checksum) |> Base58.encode_from_binary(),
      depth: depth,
      child_number: child_number,
      parent_fingerprint: parent_fingerprint
    }
  end
end
