defmodule BIP32.Xpub do
  alias Secp256Point
  alias PrivateKey
  alias Point
  alias Helpers

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
    # %Point{} of the pubkey
    :pubkey_point,
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

    parent_fingerprint =
      parent_fingerprint |> :binary.encode_unsigned(:big) |> Helpers.pad_binary(4)

    child_number = child_number |> :binary.encode_unsigned(:big) |> Helpers.pad_binary(4)

    xpub = %__MODULE__{
      chain_code: chain_code,
      public_key: compressed_pubkey,
      pubkey_point: pubkey_point,
      encoded_xpub: "",
      depth: depth,
      child_number: child_number,
      parent_fingerprint: parent_fingerprint
    }

    %__MODULE__{
      xpub
      | encoded_xpub: encoded_xpub(xpub, compressed_pubkey)
    }
  end

  defp encoded_xpub(
         %BIP32.Xpub{
           parent_fingerprint: parent_fingerprint,
           child_number: child_number,
           chain_code: chain_code,
           depth: depth
         },
         compressed_pubkey
       )
       when is_binary(parent_fingerprint) and is_binary(child_number) and
              is_binary(compressed_pubkey) and
              byte_size(chain_code) == 32 do
    # For mainnet
    version_bytes = @mainnet_xpub_version |> :binary.encode_unsigned(:big)
    4 = byte_size(version_bytes)

    4 = byte_size(parent_fingerprint)

    4 = byte_size(child_number)

    ext_pubkey = compressed_pubkey |> Helpers.pad_binary(33)
    33 = byte_size(ext_pubkey)

    concat_bin =
      version_bytes <>
        <<depth>> <> parent_fingerprint <> child_number <> chain_code <> ext_pubkey

    <<checksum::binary-size(4), _::binary>> =
      concat_bin |> CryptoUtils.hash256() |> CryptoUtils.hash256()

    (concat_bin <> checksum) |> Base58.encode_from_binary()
  end

  # for non-hardened keys only
  def derive_child(
        %BIP32.Xpub{
          public_key: parent_compressed_sec,
          pubkey_point: parent_point,
          chain_code: parent_chain_code,
          depth: parent_depth
        },
        index
      )
      when index >= 0 and index < 0x80000000 do
    index = index |> :binary.encode_unsigned(:big) |> Helpers.pad_binary(4)
    hmac = :crypto.mac(:hmac, :sha512, parent_chain_code, parent_compressed_sec <> index)
    # il - the master key
    # ir - the master chain code
    <<il::binary-size(32), child_chain_code::binary-size(32)>> = hmac
    scalar_il = :binary.decode_unsigned(il, :big)
    g = Secp256Point.get_g()
    # Compute point from scalar
    point_il = Secp256Point.mul(g, scalar_il)
    # add to parent public key K_i = point(IL) + K_parent
    child_point = Point.add(point_il, parent_point)
    child_compressed_pubkey = Secp256Point.compressed_sec(child_point)

    <<child_fingerprint::binary-size(4), _rest::binary>> =
      CryptoUtils.hash160(child_compressed_pubkey)

    child_pubkey = %__MODULE__{
      chain_code: child_chain_code,
      public_key: child_compressed_pubkey,
      pubkey_point: child_point,
      encoded_xpub: nil,
      depth: parent_depth + 1,
      child_number: index,
      parent_fingerprint: child_fingerprint
    }

    %__MODULE__{
      child_pubkey
      | encoded_xpub: encoded_xpub(child_pubkey, child_compressed_pubkey)
    }
  end

  def address(%BIP32.Xpub{public_key: public_key}, opts \\ []) do
    h160 = CryptoUtils.hash160(public_key)

    is_testnet = Keyword.get(opts, :testnet, false)
    type = Keyword.get(opts, :type, :base58)

    prefix =
      if is_testnet do
        <<0x6F>>
      else
        <<0x00>>
      end

    case type do
      :base58 ->
        Base58.encode_base58_checksum(prefix <> h160)

      _ ->
        {:error, "Type not supported #{type}"}
    end
  end
end
