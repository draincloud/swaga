defmodule BIP32.Xprv do
  require IEx

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

  def new_master(seed) do
    hmac = :crypto.mac(:hmac, :sha512, "Bitcoin seed", seed)
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
       when is_binary(secret) do
    # For mainnet
    version_bytes = 0x0488ADE4 |> :binary.encode_unsigned(:big)
    depth = <<depth>>

    parent_fingerprint =
      parent_fingerprint |> :binary.encode_unsigned(:big) |> Helpers.pad_binary(4)

    child_number = child_number |> :binary.encode_unsigned(:big) |> Helpers.pad_binary(4)
    # Prefix the 32 byte il to make it 33 bytes
    secret = <<0x00>> <> secret
    # Check for byte_sizes
    4 = byte_size(version_bytes)
    1 = byte_size(depth)
    4 = byte_size(parent_fingerprint)
    4 = byte_size(child_number)
    # those are binary values
    32 = byte_size(chain_code)
    33 = byte_size(secret)

    concat_bin =
      version_bytes <> depth <> parent_fingerprint <> child_number <> chain_code <> secret

    <<checksum::binary-size(4), _::binary>> =
      concat_bin |> CryptoUtils.hash256() |> CryptoUtils.hash256()

    IEx.pry()

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

  # non-hardened, 0x80000000 is a threshold for hardened
  def ckd_priv(xprv, index) when is_integer(index) and index < 0x80000000 do
    pub_key = Secp256Point.compressed_sec(xprv.point)
    data = pub_key <> <<index::unsigned-big-integer-size(32)>>
    hmac = :crypto.mac(:hmac, :sha512, xprv.chain_code, data)
    ckd_priv_finalize(xprv, hmac, index)
  end

  # pass only raw index values, not pre-hardened
  def ckd_priv(xprv, index) when is_integer(index) and index >= 0x80000000 do
    data = <<0>> <> xprv.secret <> <<index>>
    hmac = :crypto.mac(:hmac, :sha512, xprv.chain_code, data)
    ckd_priv_finalize(xprv, hmac, index)
  end

  def ckd_priv_finalize(xprv, hmac, i) when is_binary(hmac) do
    <<il::binary-size(32), ir::binary-size(32)>> = hmac
    il_int = :binary.decode_unsigned(il)
    secret_int = :binary.decode_unsigned(xprv.secret)
    n = Secp256Point.n()

    # k_child = (IL + k_parent) % n - Child pk derivation formula
    new_secret = rem(il_int + secret_int, n)

    xprv = %{
      raw_secret: new_secret,
      chain_code: ir,
      depth: xprv.depth + 1,
      child_number: i,
      parent_fingerprint: xprv.parent_fingerprint
    }

    xpub = BIP32.Xpub.from_xprv(xprv)

    %__MODULE__{
      encoded_xprv: raw_xprv_to_bip32_format(xprv),
      private_key: new_secret,
      chain_code: ir,
      xpub: BIP32.Xpub.from_xprv(xprv),
      depth: xprv.depth,
      child_number: 0,
      parent_fingerprint: xprv.parent_fingerprint
    }
  end
end
