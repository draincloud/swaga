defmodule Transaction.PSBT.Input do
  @doc """
      1. Utxo info
          - `PSBT_IN_NON_WITNESS_UTXO`, for older, non-segwit inputs, the entire previous transaction
          - `PSBT_IN_WITNESS_UTXO`, only the specific utxo from the prev tx is needed
      2. Script information, signer needs to know the rules for unlocking the funds it's being asked to spend.
          - `PSBT_IN_REDEEM_SCRIPT` - spending P2SH you must provide this script
          - `PSBT_IN_WITNESS_SCRIPT` - same concept but for P2WSH
      3. Key derivation, wallet needs to know which key to use
          - `PSBT_IN_BIP32_DERIVATION` - path to the key
  """
  defstruct [
    :non_witness_utxo,
    :witness_utxo,
    :redeem_script,
    :witness_script,
    :bip32_derivation
  ]
end
