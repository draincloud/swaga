defmodule Transaction.PSBT do
  alias PrivateKey
  alias Script
  alias Helpers
  alias Transaction.Input
  alias Transaction.Output
  alias Sdk.RpcClient

  defstruct [
    :unsigned_transaction,
    :psbt_inputs,
    :global_data
  ]

  @enforce_keys [
    :unsigned_transaction,
    :psbt_inputs
  ]

  @type t :: %__MODULE__{unsigned_transaction: binary(), psbt_inputs: Transaction.PSBT.Input.t()}

  @doc """
  ## CREATOR ROLE
  Signing info means adding specific pieces of data into the per-input fields
  """
  def new(%Transaction{tx_ins: inputs} = tx) do
    psbt_inputs = for _ <- inputs, do: %Transaction.PSBT.Input{}
    %__MODULE__{unsigned_transaction: tx, psbt_inputs: psbt_inputs}
  end

  @doc """
  ## UPDATER ROLE
  Signing info means adding specific pieces of data into the per-input fields
  """
  def add_sign_info(%__MODULE__{transaction: tx, psbt_inputs: psbt_inputs} = psbt) do
    psbt_inputs
    |> Enum.map(fn input ->
      prev_out = Input.prev_out(input)

      script_pub_key =
        prev_out |> Map.get("scriptPubKey") |> Map.get("hex") |> Base.decode16!(case: :lower)

      value = prev_out |> Map.get("value") |> Common.convert_to_satoshis() |> trunc()

      script_type = Script.identify_script_type(script_pub_key)

      case script_type do
        :p2wpkh ->
          witness_utxo_data = %{value: value}

          %Transaction.PSBT.Input{
            input
            | witness_utxo: witness_utxo_data,
              witness_script: :script_from_wallet
          }

        type when type in [:p2wsh, :p2tr] ->
          witness_utxo_data = %{value: value}

          %Transaction.PSBT.Input{
            input
            | witness_utxo: witness_utxo_data,
              witness_script: nil
          }

        :p2pkh ->
          # Entire transaction in hex
          prev_output = prev_out |> Map.get("hex")

          %Transaction.PSBT.Input{
            input
            | non_witness_utxo: prev_output,
              redeem_script: nil
          }

        type when type in [:p2pkh, :p2sh, :p2pk] ->
          # Entire transaction in hex
          prev_output = prev_out |> Map.get("hex")

          %Transaction.PSBT.Input{
            input
            | non_witness_utxo: prev_output,
              # The script must be given from out source
              redeem_script: :script_from_wallet
          }
      end
    end)

    %__MODULE__{psbt | psbt_inputs: psbt_inputs}
  end

  # Replace with the keypair
  def sign_input(
        %__MODULE__{unsigned_transaction: tx, psbt_inputs: psbt_inputs},
        input_index,
        %PrivateKey{},
        %BIP32.Xpub{
          public_key: public_key
        }
      ) do
    psbt_input = Enum.at(psbt_inputs, input_index)

    script_type =
      cond do
        psbt_input.witness_utxo != nil and psbt_input.witness_script != nil -> :p2wsh
        psbt_input.witness_utxo != nil -> :p2wpkh
        psbt_input.non_witness_utxo != nil and psbt_input.redeem_script != nil -> :p2sh
        psbt_input.non_witness_utxo != nil -> :p2pkh
        true -> :unknown
      end

    z =
      case script_type do
        # For segwit inputs, we use the BIP143
        :p2pwkh ->
          # Script code is a reconstructed P2PKH script
          pubkey_hash = public_key |> CryptoUtils.hash160()
          script_code = Script.p2pkh_script(pubkey_hash)

          Transaction.Segwit.BIP143.sig_hash(
            tx,
            input_index,
            script_code,
            psbt_input.witness_utxo.value
          )

        :p2wsh ->
          # For P2WSH the scriptCode is the witnessScript itself
          script_code = psbt_input.witness_script

          Transaction.Segwit.BIP143.sig_hash(
            tx,
            input_index,
            script_code,
            psbt_input.witness_utxo.value
          )

        :p2pkh ->
          script_pub_key = psbt_input.non_witness_utxo
          Transaction.sig_hash(tx, input_index)

        :p2sh ->
          script_code = psbt_input.redeem_script
          Transaction.sig_hash(tx, input_index, script_code)

        _ ->
          {:error, "Unsupported input type for signing"}
      end

    der = PrivateKey.sign(private_key, z) |> Signature.der()
    # The signature is a combination of the DER signature and the hash type
    sig = der <> :binary.encode_unsigned(@sighash_all, :big)
    sec = private_key.point |> Secp256Point.compressed_sec()
    new_partial_sig = %{pubkey: sec, signature: sig}
  end

  def combine(psbts) when is_list(psbts) do
    {:ok} = Helpers.validate_list_of_structs(psbts, __MODULE__)
  end

  def finalize(%__MODULE__{}) do
  end

  def extract_transaction(%__MODULE__{}) do
  end
end
