defmodule BIP32.Xpriv do
  require IEx
  @enforce_keys [:secret, :master_pubkey, :chain_code]
  defstruct [
    # Encoded format (xprv)
    :secret,
    # raw_binary
    :raw_secret,
    :master_pubkey,
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
    # compute the corresponding public key point
    priv_key = :binary.decode_unsigned(il)

    encoded_xpriv =
      raw_xpriv_to_bip32_format(%{
        secret: il,
        chain_code: ir,
        depth: 0,
        child_number: 0,
        # For master key the fingerprint must be zero value
        parent_fingerprint: 0x00000000
      })

    %__MODULE__{
      raw_secret: priv_key,
      secret: encoded_xpriv,
      chain_code: ir,
      master_pubkey: BIP32.Xpub.from_xpriv(priv_key, ir),
      depth: 0,
      child_number: 0,
      parent_fingerprint: 0x00000000
    }
  end

  defp raw_xpriv_to_bip32_format(%{
         secret: secret,
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
  def derive(xpriv, path) when is_binary(path) do
    indices = BIP32.DerivationPath.parse(path)

    Enum.reduce(indices, xpriv, fn i, derived_xpriv ->
      ckd_priv(derived_xpriv, i)
    end)
  end

  #  def derive_xpriv(%{chain_code: chain_code, secret: secret} = xpriv, depth, index) do
  #    priv = ckd_priv(xpriv, index)
  #
  #    #    data =
  #    #      <<0x00>> <> chain_code <> secret <> <<index + 0x80000000::unsigned-big-integer-size(32)>>
  #    #
  #    #    hmac = :crypto.mac(:hmac, :sha512, xpriv.chain_code, data)
  #    #    <<il::binary-size(32), ir::binary-size(32)>> = hmac
  #    #    priv_key = :binary.decode_unsigned(il)
  #    #    secret_int = :binary.decode_unsigned(xpriv.secret)
  #    #    n = Secp256Point.n()
  #    #
  #    #    # k_child = (IL + k_parent) % n - Child pk derivation formula
  #    #    new_secret_int = rem(priv_key + secret_int, n)
  #
  #    #    encoded_xpriv =
  #    #      raw_xpriv_to_bip32_format(%{
  #    #        secret: il,
  #    #        chain_code: ir,
  #    #        depth: 0,
  #    #        child_number: 0,
  #    #        # For master key the fingerprint must be zero value
  #    #        parent_fingerprint: 0x00000000
  #    #      })
  #    #
  #    encoded_xpriv = raw_xpriv_to_bip32_format(priv)
  #
  #    %__MODULE__{
  #      secret: encoded_xpriv,
  #      chain_code: priv.chain_code,
  #      master_pubkey: BIP32.Xpub.from_xpriv(priv.raw_secret, priv.chain_code),
  #      depth: 0,
  #      child_number: 0,
  #      parent_fingerprint: 0x00000000
  #    }
  #  end

  # non-hardened, 0x80000000 is a threshold for hardened
  def ckd_priv(xpriv, index) when is_integer(index) and index < 0x80000000 do
    pub_key = Secp256Point.compressed_sec(xpriv.point)
    data = pub_key <> <<index::unsigned-big-integer-size(32)>>
    hmac = :crypto.mac(:hmac, :sha512, xpriv.chain_code, data)
    ckd_priv_finalize(xpriv, hmac, index)
  end

  # pass only raw index values, not pre-hardened
  def ckd_priv(xpriv, index) when is_integer(index) and index >= 0x80000000 do
    data = <<0>> <> xpriv.secret <> <<index>>
    hmac = :crypto.mac(:hmac, :sha512, xpriv.chain_code, data)
    ckd_priv_finalize(xpriv, hmac, index)
  end

  def ckd_priv_finalize(xpriv, hmac, i) when is_binary(hmac) do
    <<il::binary-size(32), ir::binary-size(32)>> = hmac
    il_int = :binary.decode_unsigned(il)
    secret_int = :binary.decode_unsigned(xpriv.secret)
    n = Secp256Point.n()

    # k_child = (IL + k_parent) % n - Child pk derivation formula
    new_secret_int = rem(il_int + secret_int, n)
    new_secret = <<new_secret_int::unsigned-big-integer-size(256)>>

    master_pubkey = BI

    fingerprint =
      %__MODULE__{
        secret: new_secret,
        chain_code: ir,
        master_pubkey: BIP32.Xpub.from_xpriv(new_secret, ir),
        depth: xpriv.depth + 1,
        child_number: i,
        parent_fingerprint: fingerprint
      }
  end
end
