defmodule Tx do
  @moduledoc """
  Represents a Bitcoin transaction, including inputs, outputs, and metadata.
  Provides functions for parsing, serializing, signing, verifying, and computing fees and IDs.
  """
  @type t :: %__MODULE__{
          version: non_neg_integer(),
          tx_ins: [TxIn.t()],
          tx_outs: [TxOut.t()],
          locktime: non_neg_integer(),
          testnet: boolean()
        }

  @enforce_keys [
    :version,
    :tx_ins
  ]

  defstruct [
    :version,
    :tx_ins,
    :tx_outs,
    :locktime,
    :testnet
  ]

  @sighash_all 1

  @doc """
  Creates a new Bitcoin transaction.

  ## Parameters
    - version: Transaction version (integer).
    - tx_ins: List of transaction inputs (%TxIn{}).
    - tx_outs: List of transaction outputs (%TxOut{}).
    - locktime: Locktime (integer).
    - testnet: Boolean indicating testnet (true) or mainnet (false).

  ## Returns
    - %Tx{} if valid.
    - {:error, reason} if invalid.
  """
  def new(
        version,
        tx_ins,
        tx_outs,
        locktime,
        testnet
      )
      when is_integer(version) and version > 0 and is_list(tx_ins) and is_list(tx_outs) and
             is_integer(locktime) and locktime >= 0 and
             is_boolean(testnet) do
    if Enum.all?(tx_ins, &is_struct(&1, TxIn)) and Enum.all?(tx_outs, &is_struct(&1, TxOut)) do
      %Tx{
        version: version,
        tx_ins: tx_ins,
        tx_outs: tx_outs,
        locktime: locktime,
        testnet: testnet
      }
    else
      {:error, :invalid_inputs_or_outputs}
    end
  end

  def new(_version, _tx_ins, _tx_outs, _locktime, _testnet), do: {:error, :invalid_input}

  @doc """
  Returns the command identifier for transactions.

  ## Returns
    - "tx"
  """
  def command, do: "tx"

  @doc """
  Reads a variable-length integer from a binary.

  ## Parameters
    - binary: Binary containing the varint.

  ## Returns
    - {integer, remaining_binary} if valid.
    - {:error, reason} if invalid.
  """
  def read_varint(<<prefix, rest::binary>>) when prefix < 0xFD, do: {prefix, rest}

  def read_varint(<<0xFD, two_bytes::binary-size(2), rest::binary>>),
    do: {MathUtils.little_endian_to_int(two_bytes), rest}

  def read_varint(<<0xFE, four_bytes::binary-size(4), rest::binary>>),
    do: {MathUtils.little_endian_to_int(four_bytes), rest}

  def read_varint(<<0xFF, eight_bytes::binary-size(8), rest::binary>>),
    do: {MathUtils.little_endian_to_int(eight_bytes), rest}

  def read_varint(_bin), do: {:error, :invalid_varint}

  @doc """
  Encodes an integer as a variable-length integer.

  ## Parameters
    - i: Non-negative integer.

  ## Returns
    - binary() with encoded varint.
    - {:error, reason} if invalid.
  """
  def encode_varint(i) when i < 0xFD do
    <<i>>
  end

  def encode_varint(i) when i < 0x10000 do
    <<0xFD>> <> MathUtils.int_to_little_endian(i, 2)
  end

  def encode_varint(i) when i < 0x100000000 do
    <<0xFE>> <> MathUtils.int_to_little_endian(i, 4)
  end

  def encode_varint(i) when i < 0x10000000000000000 do
    <<0xFF>> <> MathUtils.int_to_little_endian(i, 8)
  end

  def encode_varint(i) when i < 0x10000000000000000 do
    {:error, :integer_too_large}
  end

  def encode_varint(_i), do: {:error, :invalid_integer}

  @doc """
  Parses a serialized Bitcoin transaction.

  ## Parameters
    - serialized_tx: Binary in Bitcoin wire format.
    - testnet: Boolean indicating testnet (default: false).

  ## Returns
    - %Tx{} if valid.
    - {:error, reason} if invalid.
  """
  def parse(tx, testnet \\ false)

  def parse(serialized_tx, testnet) when is_binary(serialized_tx) do
    <<version_bin::binary-size(4), rest::binary>> = serialized_tx
    {num_inputs, tx_rest} = read_varint(rest)

    {inputs, final_rest} =
      Enum.reduce(1..num_inputs, {[], tx_rest}, fn _, {acc, bin} ->
        {new_bin, input} = TxIn.parse(bin)
        {[input | acc], new_bin}
      end)

    {num_outputs, tx_rest} = read_varint(final_rest)

    {outputs, final_rest} =
      Enum.reduce(1..num_outputs, {[], tx_rest}, fn _, {acc, bin} ->
        {new_bin, output} = TxOut.parse(bin)
        {[output | acc], new_bin}
      end)

    <<raw_locktime::binary-size(4), _::binary>> = final_rest
    locktime = MathUtils.little_endian_to_int(raw_locktime)

    %Tx{
      version: MathUtils.little_endian_to_int(version_bin),
      tx_ins: inputs |> Enum.reverse(),
      tx_outs: outputs |> Enum.reverse(),
      locktime: locktime,
      testnet: testnet
    }
  end

  def parse(_tx, _testnet), do: {:error, :invalid_input}

  @doc """
  Calculates the transaction fee (input sum minus output sum).

  ## Parameters
    - tx: Transaction (%Tx{}).
    - testnet: Boolean for testnet (default: false).

  ## Returns
    - integer() if valid.
    - {:error, reason} if invalid.
  """
  def fee(%{tx_ins: inputs, tx_outs: outputs}, testnet \\ false) do
    input_sum = Enum.reduce(inputs, 0, fn input, acc -> acc + TxIn.value(input, testnet) end)
    output_sum = Enum.reduce(outputs, 0, fn output, acc -> acc + output.amount end)

    fee = input_sum - output_sum

    cond do
      fee < 0 -> {:error, :negative_fee}
      fee == 0 -> {:error, :empty_fee}
      fee > 0 -> fee
    end
  end

  @doc """
  Computes the signature hash (z) for a transaction input.

  ## Parameters
    - tx: Transaction (%Tx{}).
    - input_index: Index of the input to sign.

  ## Returns
    - integer() with the signature hash.
    - {:error, reason} if invalid.
  """
  def sig_hash(
        %Tx{
          version: version,
          tx_ins: inputs,
          tx_outs: outputs,
          testnet: testnet,
          locktime: locktime
        },
        input_index
      )
      when is_integer(input_index) and input_index >= 0 and input_index < length(inputs) do
    # Checking the signature.
    # A transaction has at least one signature per input.
    # We use op_code OP_CHECKSIG, but the hard part is getting the signature hash to validate it.
    # That's why we modify the transaction before signing it, we compute a different signature hash for each input.
    #  Returns the integer representation of the hash that needs to get
    #  signed for index input_index
    # start the serialization with version
    # use int_to_little_endian in 4 bytes
    signature = MathUtils.int_to_little_endian(version, 4)
    # add how many inputs there are using encode_varint
    signature = signature <> encode_varint(length(inputs))

    # loop through each input
    inputs_signatures =
      inputs
      |> Enum.with_index()
      |> Enum.reduce("", fn {inp, i}, acc ->
        # if the input index is ht one we're signing
        script_pubkey =
          if i == input_index do
            # If the RedeemScript (p2sh script) was passed in -> that's the ScriptSig
            # otherwise the previous tx's ScriptPubkey is the ScriptSig
            TxIn.script_pubkey(inp, testnet)
          else
            nil
            # Otherwise, the ScriptSig is nil
          end

        new_input = TxIn.new(inp.prev_tx, inp.prev_index, script_pubkey, inp.sequence)
        serialized = TxIn.serialize(new_input)
        acc <> serialized
      end)

    signature = signature <> inputs_signatures
    signature = signature <> encode_varint(length(outputs))

    serialized_outputs =
      Enum.reduce(outputs, "", fn output, acc ->
        acc <> TxOut.serialize(output)
      end)

    signature = signature <> serialized_outputs
    signature = signature <> MathUtils.int_to_little_endian(locktime, 4)
    signature = signature <> MathUtils.int_to_little_endian(@sighash_all, 4)
    CryptoUtils.double_hash256(signature)
  end

  # Returns whether the input has a valid signature
  def verify_input(%Tx{tx_ins: inputs, testnet: testnet} = tx, input_index) do
    # Get the relevant input
    input = Enum.at(inputs, input_index)
    # Grab the previous ScriptPubKey
    script_pubkey = TxIn.script_pubkey(input, testnet)
    # Get the signature hash(z)
    # Pass the redeemScript ot the sig_hash method
    z = sig_hash(tx, input_index)
    # Combined the current ScriptSig and the previous ScriptPubkey
    combined = Script.add(input.script_sig, script_pubkey)
    # evaluate the combined script
    Script.evaluate(combined, z)
  end

  def verify(%Tx{tx_ins: inputs} = tx) do
    if fee(tx) < 0 do
      false
    else
      inputs
      |> Enum.with_index()
      |> Enum.all?(fn {_input, i} -> verify_input(tx, i) end)
    end
  end

  def hash(%Tx{} = tx) do
    tx
    |> Tx.serialize()
    |> CryptoUtils.hash256()
    |> CryptoUtils.hash256()
    |> :binary.bin_to_list()
    |> Enum.reverse()
    |> :binary.list_to_bin()
  end

  def id(%Tx{} = tx) do
    tx |> hash |> Base.encode16(case: :lower)
  end

  # Returns the byte serialization of the transaction
  def serialize(%Tx{
        version: version,
        tx_ins: tx_ins,
        tx_outs: tx_outs,
        locktime: locktime
      }) do
    # Serialize version
    result = MathUtils.int_to_little_endian(version, 4)
    # Encode varint on the number of inputs
    result = result <> encode_varint(length(tx_ins))

    # Serialize each input
    serialized_inputs =
      Enum.reduce(tx_ins, "", fn inp, acc ->
        acc <> TxIn.serialize(inp)
      end)

    result = result <> serialized_inputs <> encode_varint(length(tx_outs))

    serialized_outputs =
      Enum.reduce(tx_outs, "", fn out, acc ->
        serialized_output = TxOut.serialize(out)
        acc <> serialized_output
      end)

    result = result <> serialized_outputs
    result <> MathUtils.int_to_little_endian(locktime, 4)
  end

  def sign_input(%Tx{} = tx, input_index, %PrivateKey{} = private_key) do
    # Sign the first input
    z = sig_hash(tx, input_index)
    der = PrivateKey.sign(private_key, z) |> Signature.der()
    # The signature is a combination of the DER signature and the hash type
    sig = der <> :binary.encode_unsigned(@sighash_all, :big)
    sec = private_key.point |> Secp256Point.compressed_sec()
    # The scriptSig of a p2pkh has two elements, the signature and SEC format public key
    script_sig = Script.new([sig, sec])

    updated_inputs =
      List.replace_at(tx.tx_ins, input_index, %TxIn{
        Enum.at(tx.tx_ins, input_index)
        | script_sig: script_sig
      })

    updated = %Tx{tx | tx_ins: updated_inputs}
    {verify_input(updated, input_index), updated}
  end

  def is_coinbase(%Tx{tx_ins: inputs}) when length(inputs) == 1 do
    [only_input] = inputs
    TxIn.is_coinbase(only_input)
  end

  def is_coinbase(%Tx{}) do
    false
  end

  # According to BIP0034, scriptSig first element is height in coinbase tx
  def coinbase_height(%Tx{tx_ins: inputs} = tx) do
    if is_coinbase(tx) do
      [only_input] = inputs
      [coin_base_height | _] = only_input.script_sig.cmds
      MathUtils.little_endian_to_int(coin_base_height)
    else
      nil
    end
  end
end
