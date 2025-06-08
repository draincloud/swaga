defmodule Transaction.PSBT do
  alias PrivateKey
  alias Script
  alias Helpers
  alias Transaction.Input
  alias Transaction.Output
  alias Sdk.RpcClient

  defstruct [
    :transaction,
    :derive_path,
    :psbt_in_non_witness_utxo,
    :psbt_in_witness_utxo,
    :psbt_in_redeem_script,
    :psbt_in_witness_script,
    :psbt_in_bip32_derivation
  ]

  def new(%Transaction{} = tx, derive_path) when is_binary(derive_path) do
    %__MODULE__{transaction: tx, derive_path: derive_path}
  end

  @doc """
  ## UPDATER ROLE
  Signing info means adding specific pieces of data into the per-input fields
  1. Utxo info
      - `PSBT_IN_NON_WITNESS_UTXO`, for older, non-segwit inputs, the entire previous transaction
      - `PSBT_IN_WITNESS_UTXO`, only the specific utxo from the prev tx is needed
  2. Script information, signer needs to know the rules for unlocking the funds it's being asked to spend.
      - `PSBT_IN_REDEEM_SCRIPT` - spending P2SH you must provide this script
      - `PSBT_IN_WITNESS_SCRIPT` - same concept but for P2WSH
  3. Key derivation, wallet needs to know which key to use
      - `PSBT_IN_BIP32_DERIVATION` - path to the key
  """
  def add_sign_info(%__MODULE__{transaction: tx, derive_path: derive_path} = psbt) do
    tx.tx_ins
    |> Enum.map(fn input ->
      script_pub_key = Input.script_pubkey(input) |> Base.decode16!(case: :lower)

      # Rewrite structure, into having multiple inputs
      # psbt_in_witness_utxo must have type %{value, script_pubkey}
      case Script.identify_script_type(script_pub_key) do
        type when type in [:p2wpkh, :p2wsh, :p2tr] ->
          %__MODULE__{psbt | psbt_in_witness_utxo: script_pub_key}

        type when type in [:p2pkh, :p2sh, :p2pk] ->
          # Entire transaction in hex
          prev_output = Input.prev_out(input) |> Map.get("hex")
          %__MODULE__{psbt | psbt_in_non_witness_utxo: prev_output}
      end
    end)
  end

  def sign_input(%__MODULE__{}, input_index, %PrivateKey{}) do
  end

  def combine(psbts) when is_list(psbts) do
    {:ok} = Helpers.validate_list_of_structs(psbts, __MODULE__)
  end

  def finalize(%__MODULE__{}) do
  end

  def extract_transaction(%__MODULE__{}) do
  end
end
