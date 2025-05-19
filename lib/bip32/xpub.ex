defmodule Xpub do
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

  def from_xpriv(%Xpriv{
        depth: depth,
        parent_fingerprint: parent_fingerprint,
        child_number: child_number,
        chain_code: chain_code,
        secret: secret
      }) do
    %__MODULE__{
      chain_code: chain_code,
      public_key: Secp256Point.compressed_sec(secret),
      depth: depth,
      child_number: child_number,
      parent_fingerprint: parent_fingerprint
    }
  end
end
