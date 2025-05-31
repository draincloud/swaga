defmodule BIP32.Xprv do
  @doc """
  BIP32 implementation.
  Implementation of BIP32 hierarchical deterministic wallets, as defined
  at <https://github.com/bitcoin/bips/blob/master/bip-0032.mediawiki>.
  --------
  Private parent key → private child key
  Chain code adds entropy to ensure child keys cannot be derived just from the private key alone.
  Child derivation differs for hardened vs non-hardened keys:
  If i >= 2³¹, it's a hardened child
  """
  @mainnet_xprv_version 0x0488ADE4
  @enforce_keys [
    :encoded_xprv,
    :private_key,
    :xpub,
    :chain_code,
    :depth,
    :child_number,
    :parent_fingerprint
  ]

  defstruct [
    # Encoded format (xprv)
    :encoded_xprv,
    # raw_binary
    :private_key,
    :xpub,
    :chain_code,
    # depth in HD tree (0 for master)
    :depth,
    # child index (0 for master)
    :child_number,
    # first 4 bytes of parent pubkey hash160
    :parent_fingerprint
  ]

  def new_master(seed) when is_binary(seed) do
    # Convert to hex decode binary, if it's an hex string
    converted_seed =
      case Helpers.is_hex_string?(seed) do
        true -> seed |> Base.decode16!(case: :mixed)
        false -> seed
      end

    hmac = :crypto.mac(:hmac, :sha512, "Bitcoin seed", converted_seed)
    # il - the master key
    # ir - the master chain code
    <<il::binary-size(32), ir::binary-size(32)>> = hmac

    xprv = %__MODULE__{
      encoded_xprv: nil,
      private_key: il,
      chain_code: ir,
      depth: 0,
      child_number: 0,
      parent_fingerprint: 0x00000000,
      xpub: nil
    }

    %__MODULE__{
      xprv
      | encoded_xprv: raw_xprv_to_bip32_format(xprv),
        xpub: BIP32.Xpub.from_xprv(xprv)
    }
  end

  defp raw_xprv_to_bip32_format(%{private_key: secret} = xprv) when is_integer(secret) do
    raw_xprv_to_bip32_format(%{xprv | private_key: secret |> :binary.encode_unsigned(:big)})
  end

  defp raw_xprv_to_bip32_format(%{
         private_key: secret,
         depth: depth,
         parent_fingerprint: parent_fingerprint,
         chain_code: chain_code,
         child_number: child_number
       })
       when is_binary(secret) and byte_size(secret) == 32 and
              is_integer(depth) and depth >= 0 and depth <= 255 and
              is_binary(chain_code) and byte_size(chain_code) == 32 and
              is_integer(child_number) do
    # For mainnet
    version_bytes = @mainnet_xprv_version |> :binary.encode_unsigned(:big)

    child_number = child_number |> :binary.encode_unsigned(:big) |> Binary.Common.pad_binary(4)
    # Prefix the 32 byte il to make it 33 bytes
    secret = <<0x00>> <> secret
    # Check for byte_sizes
    4 = byte_size(version_bytes)
    depth = <<depth>>
    1 = byte_size(depth)

    parent_fingerprint =
      parent_fingerprint |> :binary.encode_unsigned(:big) |> Binary.Common.pad_binary(4)

    4 = byte_size(parent_fingerprint)
    4 = byte_size(child_number)
    # those are binary values
    32 = byte_size(chain_code)
    33 = byte_size(secret)

    concat_bin =
      version_bytes <> depth <> parent_fingerprint <> child_number <> chain_code <> secret

    <<checksum::binary-size(4), _::binary>> =
      concat_bin |> CryptoUtils.hash256() |> CryptoUtils.hash256()

    (concat_bin <> checksum) |> Base58.encode_from_binary()
  end

  @doc """
  Derives an extended private key from a path
  """
  def derive(xprv, path) when is_binary(path) do
    indices = BIP32.DerivationPath.parse(path)

    Enum.reduce(indices, xprv, fn i, child_xprv ->
      ckd_priv(child_xprv, i)
    end)
  end

  # Always convert private_key to binary
  def ckd_priv(%{private_key: private_key} = xprv, index) when is_integer(private_key) do
    ckd_priv(%{xprv | private_key: private_key |> :binary.encode_unsigned()}, index)
  end

  # non-hardened, 0x80000000 is a threshold for hardened
  def ckd_priv(%{private_key: private_key, chain_code: chain_code} = xprv, index)
      when is_integer(index) and index >= 0 and index < 0x80000000 do
    g = Secp256Point.get_g()
    pubkey_point = Secp256Point.mul(g, private_key)
    parent_pubkey = Secp256Point.compressed_sec(pubkey_point)
    data = parent_pubkey <> <<index::unsigned-big-integer-size(32)>>
    hmac = :crypto.mac(:hmac, :sha512, chain_code, data)
    ckd_priv_finalize(xprv, hmac, index)
  end

  # hardened derive
  def ckd_priv(xprv, index)
      when is_integer(index) and index > 0 and index >= 0x80000000 and index < 0xFFFFFFFF do
    data = <<0>> <> xprv.private_key <> <<index::unsigned-big-integer-size(32)>>
    hmac = :crypto.mac(:hmac, :sha512, xprv.chain_code, data)
    ckd_priv_finalize(xprv, hmac, index)
  end

  def ckd_priv_finalize(%{private_key: private_key} = xprv, hmac, i)
      when is_integer(private_key) do
    ckd_priv_finalize(%{xprv | private_key: private_key |> :binary.encode_unsigned()}, hmac, i)
  end

  def ckd_priv_finalize(%{private_key: private_key} = xprv, hmac, i)
      when is_binary(hmac) and is_binary(private_key) do
    <<il::binary-size(32), ir::binary-size(32)>> = hmac
    il_int = :binary.decode_unsigned(il)
    secret_int = :binary.decode_unsigned(private_key)
    n = Secp256Point.n()

    # k_child = (IL + k_parent) % n - Child pk derivation formula
    new_secret = rem(il_int + secret_int, n)

    <<parent_fingerprint::binary-size(4), _::binary>> =
      xprv.xpub.public_key |> CryptoUtils.hash160()

    xprv = %__MODULE__{
      encoded_xprv: nil,
      xpub: nil,
      private_key: new_secret,
      chain_code: ir,
      depth: xprv.depth + 1,
      child_number: i,
      parent_fingerprint: parent_fingerprint |> :binary.decode_unsigned(:big)
    }

    %__MODULE__{
      xprv
      | encoded_xprv: raw_xprv_to_bip32_format(xprv),
        xpub: BIP32.Xpub.from_xprv(xprv)
    }
  end
end
