defmodule ExtendedPrivateKey do
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

    %ExtendedPrivateKey{
      secret: il,
      chain_code: ir,
      point: pubkey_point,
      depth: 0,
      child_number: 0,
      parent_fingerprint: <<>>
    }
  end
end
