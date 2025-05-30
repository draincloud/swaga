defmodule BIP32.DerivationPath do
  @doc """
  ## BIP32
  Derivation path: A sequence like m/0H/1/2H/2/1000000000, where:
  m indicates the master key.
  Numbers (e.g., 0, 1, 2, 1000000000) are child indices.
  H (or ') denotes hardened derivation (index ≥ 2³¹).
  Non-hardened (normal) derivation uses indices 0 to 2³¹−1.
  ### Hardened vs. non-hardened:
  Hardened derivation requires the parent private key and produces keys that cannot be linked to the parent public key alone.
  Non-hardened derivation allows deriving child public keys from a parent public key.
    
  ## BIP44
  This standard builds upon BIP32
  It prescribes a 5-level path hierarchy:
  `m / purpose / coin_type / account / change / address_index`
  purpose - this field is constant and set to 44
  coin_type - this field specifies the cryptocurrency. Each coin has a number (0 for BTC, 1 for BTC test)
  account - this field allows users to organize their funds into separate logical accounts. It's indexed starting from 0
  change - 0 for external chain (address intended to be shared publicly), 1 for internal chain (addresses used for change)
  address_index - indicates the sequential index of the address
  """

  defstruct [:numbers]
  # Example: m/0' or m/0H
  def parse(path) when is_binary(path) do
    components = String.split(path, "/")
    # Check that m is the first component
    "m" = Enum.at(components, 0)
    [_ | indices] = components

    Enum.map(indices, fn i ->
      {indic, _} = Integer.parse(i)

      if String.contains?(i, "'") or String.contains?(i, "H") do
        indic + 0x80000000
      else
        indic
      end
    end)
  end
end
