defmodule Transaction.Segwit.BIP143 do
  require IEx
  alias Transaction.Input
  alias Transaction.Output
  alias Transaction
  alias CryptoUtils
  alias Script
  alias MathUtils
  alias Binary.Common
  @sighash_all 1

  @doc """
  Calculates the BIP143 signature hash for a P2WPKH (Pay-to-Witness-Public-Key-Hash) input.

  This function implements the signature hashing algorithm defined in BIP143 for
  version 0 SegWit inputs, specifically for P2WPKH. The result is a 32-byte hash
  that serves as the "message" to be signed by the private key corresponding to
  the P2WPKH output being spent.

  The BIP143 sighash mechanism provides improved security and predictability by
  committing to various transaction components, including:
  - Transaction version (`nVersion`)
  - A hash of all previous output points (`hashPrevouts`)
  - A hash of all input sequence numbers (`hashSequence`)
  - The specific outpoint of the input being signed
  - The `scriptCode` (for P2WPKH, this is `OP_DUP OP_HASH160 <PubKeyHash> OP_EQUALVERIFY OP_CHECKSIG`)
  - The value (amount in satoshis) of the UTXO being spent by this input
  - The sequence number of the input being signed
  - A hash of all outputs (`hashOutputs`)
  - Transaction locktime (`nLocktime`)
  - The `sighash_type` flag

  ## Parameters
  - `transaction`: The `%Tx{}` struct representing the transaction being signed.
  It must contain `version`, `tx_ins` (list of all inputs), `tx_outs` (list of
    all outputs), and `locktime`. The `testnet` field is part of the transaction
    context but not directly used in this specific sighash calculation logic.
  - `input_index`: (Integer) The zero-based index of the P2WPKH input within
  `transaction.tx_ins` that is being signed.
  - `public_key_hash`: (Binary) The 20-byte HASH160 of the compressed public key
  corresponding to the P2WPKH output that this input is spending. This is
  used to construct the `scriptCode`.
  - `sighash_type`: (Integer, optional) The signature hash type flag, defaulting
  to `@sighash_all` (1). This flag modifies which parts of the transaction
  are included in the hash, affecting the signature's scope.

  ## Returns
  - A 32-byte binary representing the signature hash to be signed.
  - Or `{:error, reason}` if an unsupported `sighash_type` is provided (based on current implementation).
  """
  def sig_hash(
        %Transaction{
          version: version,
          tx_ins: inputs,
          tx_outs: outputs,
          locktime: locktime
        },
        input_index,
        script,
        amount,
        sighash_type \\ @sighash_all
      )
      when is_integer(input_index) and is_struct(script, Script) and is_integer(amount) do
    case sighash_type do
      @sighash_all ->
        version_le = MathUtils.int_to_little_endian(version, 4)
        hash_prev_outs = calculate_hash_prev_outs(inputs)
        hash_sequence = calculate_hash_sequence(inputs)

        input = Enum.at(inputs, input_index)
        %Input{prev_index: prev_index, prev_tx: prev_tx, sequence: sequence} = input

        prev_tx_le = Common.reverse_binary(prev_tx)
        prev_index_le = MathUtils.int_to_little_endian(prev_index, 4)
        outpoint = prev_tx_le <> prev_index_le

        script_serialized = script |> Script.serialize()

        #        amount = Input.value(input) |> MathUtils.int_to_little_endian(8)
        amount = amount |> MathUtils.int_to_little_endian(8)
        n_sequence = sequence |> MathUtils.int_to_little_endian(4)
        hash_outputs = calculate_hash_outputs(outputs)
        locktime_le = locktime |> MathUtils.int_to_little_endian(4)
        sighash_type_le = sighash_type |> MathUtils.int_to_little_endian(4)

        pre_image_elixir =
          version_le <>
            hash_prev_outs <>
            hash_sequence <>
            outpoint <>
            script_serialized <>
            amount <> n_sequence <> hash_outputs <> locktime_le <> sighash_type_le

        CryptoUtils.double_hash256(pre_image_elixir, :bin)

      _ ->
        {:error, "This sighash is currently not supported"}
    end
  end

  defp calculate_hash_prev_outs(tx_ins) when is_list(tx_ins) do
    Enum.map_join(tx_ins, fn %Input{prev_tx: prev_tx, prev_index: prev_index} ->
      prev_tx_le = Common.reverse_binary(prev_tx)
      prev_index_le = MathUtils.int_to_little_endian(prev_index, 4)
      prev_tx_le <> prev_index_le
    end)
    |> CryptoUtils.double_hash256(:bin)
  end

  defp calculate_hash_outputs(tx_outs) when is_list(tx_outs) do
    Enum.map_join(tx_outs, fn %Output{} = output ->
      Output.serialize(output)
    end)
    |> CryptoUtils.double_hash256(:bin)
  end

  defp calculate_hash_sequence(tx_ins) when is_list(tx_ins) do
    n_sequence =
      Enum.map_join(tx_ins, fn %Input{sequence: sequence} ->
        MathUtils.int_to_little_endian(sequence, 4)
      end)

    n_sequence |> CryptoUtils.double_hash256(:bin)
  end
end
