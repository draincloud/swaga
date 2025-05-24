defmodule Bip32 do
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
  def ckd_priv(parent_key, chain_code, index)
      when is_binary(parent_key) and is_binary(chain_code) and byte_size(index) == 4 do
    case index >= :math.pow(2, 31) do
      true -> hardened_key(parent_key, index)
      false -> non_hardened_key(parent_key, index)
    end
  end

  # Hardened keys are derived in such a way that you must know the parent private key to derive them
  def hardened_key(parent_private_key, index) do
    <<0x00>> <> parent_private_key <> index
  end

  # Non-hardened keys can be derived from a parent public key (extended public key)
  def non_hardened_key(parent_public_key, index) do
    parent_public_key <> index
  end
end
