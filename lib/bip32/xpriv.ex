defmodule Xpriv do
  @enforce_keys [:secret, :point, :chain_code]
  defstruct [
    :secret,
    :point,
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
    g = Secp256Point.get_g()
    pubkey_point = Secp256Point.mul(g, priv_key)

    <<finger_print::binary-size(4), _::binary>> = pubkey_point

    %__MODULE__{
      secret: il,
      chain_code: ir,
      point: pubkey_point,
      depth: 0,
      child_number: 0,
      parent_fingerprint: finger_print
    }
  end

  #  def to_xpub(xpriv) do
  #    Xpub.from_priv(xpriv)
  #  end

  @doc """
  Derives an extended private key from a path
  """
  def derive_xpriv(xpriv, child_numbers) do
    Enum.reduce(child_numbers, xpriv, fn child, sk ->
      ckd_priv(sk, child)
    end)
  end

  # non-hardened, 0x80000000 is a threshold for hardened
  def ckd_priv(xpriv, {"normal", index}) when is_integer(index) and index < 0x80000000 do
    pub_key = Secp256Point.compressed_sec(xpriv.point)
    data = pub_key <> <<index::unsigned-big-integer-size(32)>>
    hmac = :crypto.mac(:hmac, :sha512, xpriv.chain_code, data)
    ckd_priv_finalize(xpriv, hmac, index)
  end

  # pass only raw index values, not pre-hardened

  def ckd_priv(xpriv, {"hardened", index}) when is_integer(index) and index > 0x80000000 do
    data = <<0>> <> xpriv.secret <> <<index + 0x80000000::unsigned-big-integer-size(32)>>
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
    new_point = Secp256Point.from_secret_key(new_secret_int)

    fingerprint =
      xpriv.point |> Secp256Point.compressed_sec() |> CryptoUtils.hash160() |> binary_part(0, 4)

    %__MODULE__{
      secret: new_secret,
      chain_code: ir,
      point: new_point,
      depth: xpriv.depth + 1,
      child_number: i,
      parent_fingerprint: fingerprint
    }
  end
end
