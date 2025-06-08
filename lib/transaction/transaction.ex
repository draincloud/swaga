defmodule Transaction do
  require IEx
  alias Helpers
  alias Transaction.Input
  alias Transaction.Output
  alias Transaction.Segwit.BIP143

  @moduledoc """
  Represents a Bitcoin transaction, including inputs, outputs, and metadata.
  Provides functions for parsing, serializing, signing, verifying, and computing fees and IDs.
  """
  @type t :: %__MODULE__{
          version: non_neg_integer(),
          tx_ins: [Input.t()],
          tx_outs: [Output.t()],
          locktime: non_neg_integer(),
          witnesses: [[binary()]]
        }

  @enforce_keys [
    :version,
    :tx_ins,
    :tx_outs,
    :locktime,
    :witnesses
  ]

  defstruct [
    :version,
    :tx_ins,
    :tx_outs,
    :locktime,
    :witnesses
  ]

  @sighash_all 1

  @doc """
  Creates a new Bitcoin transaction.

  ## Parameters
    - version: Transaction version (integer).
    - tx_ins: List of transaction inputs (%TxIn{}).
    - tx_outs: List of transaction outputs (%TxOut{}).
    - locktime: Locktime (integer).

  ## Returns
    - %Tx{} if valid.
    - {:error, reason} if invalid.
  """
  def new(
        version,
        tx_ins,
        tx_outs,
        locktime,
        witnesses \\ nil
      )
      when is_integer(version) and version > 0 and is_list(tx_ins) and is_list(tx_outs) and
             is_integer(locktime) and locktime >= 0 do
    if Enum.all?(tx_ins, &is_struct(&1, Input)) and Enum.all?(tx_outs, &is_struct(&1, Output)) do
      %__MODULE__{
        version: version,
        tx_ins: tx_ins,
        tx_outs: tx_outs,
        locktime: locktime,
        witnesses: witnesses || List.duplicate([], length(tx_ins))
      }
    else
      {:error, :invalid_inputs_or_outputs}
    end
  end

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

  def encode_varint(_) do
    {:error, :integer_too_large}
  end

  @doc """
  Parses a serialized Bitcoin transaction.

  ## Parameters
    - serialized_tx: Binary in Bitcoin wire format.

  ## Returns
    - %Tx{} if valid.
    - {:error, reason} if invalid.
  """
  def parse(tx)

  def parse(serialized_tx) when is_binary(serialized_tx) do
    serialized_tx =
      if Helpers.is_hex_string?(serialized_tx) do
        Base.decode16!(serialized_tx, case: :mixed)
      else
        serialized_tx
      end

    <<version_bin::binary-size(4), rest::binary>> = serialized_tx
    # Check for segwit tx
    {segwit_flag, tx_bin} = is_segwit(rest)

    {inputs_count, tx_rest} = read_varint(tx_bin)

    {inputs, final_rest} =
      Enum.reduce(1..inputs_count, {[], tx_rest}, fn _, {acc, bin} ->
        {new_bin, input} = Input.parse(bin)
        {[input | acc], new_bin}
      end)

    {outputs_count, tx_rest} = read_varint(final_rest)

    {outputs, tx_rest_after_outputs} =
      Enum.reduce(1..outputs_count, {[], tx_rest}, fn _, {acc, bin} ->
        {new_bin, output} = Output.parse(bin)
        {[output | acc], new_bin}
      end)

    {witnesses, tx_rest_after_witness} =
      case segwit_flag do
        true ->
          Enum.map_reduce(1..inputs_count, tx_rest_after_outputs, fn _, bin ->
            # Read how many elements are in the witness stack for this specific input
            {witness_count, bin} = read_varint(bin)

            {input_witnesses, bin} =
              Enum.map_reduce(1..witness_count, bin, fn _, bin ->
                {witness_length, witness_bin_rest} = read_varint(bin)
                <<witness::binary-size(witness_length), bin::binary>> = witness_bin_rest
                {witness, bin}
              end)

            # 1st is stored inside new array, second is acc
            {input_witnesses, bin}
          end)

        false ->
          {[], tx_rest_after_outputs}
      end

    <<raw_locktime::binary-size(4), _::binary>> = tx_rest_after_witness
    locktime = MathUtils.little_endian_to_int(raw_locktime)

    %__MODULE__{
      version: MathUtils.little_endian_to_int(version_bin),
      tx_ins: inputs |> Enum.reverse(),
      tx_outs: outputs |> Enum.reverse(),
      locktime: locktime,
      witnesses: witnesses
    }
  end

  def parse(_tx), do: {:error, :invalid_input}

  @doc """
  Calculates the transaction fee (input sum minus output sum).

  ## Parameters
    - tx: Transaction (%Tx{}).

  ## Returns
    - integer() if valid.
    - {:error, reason} if invalid.
  """
  def fee(%{tx_ins: inputs, tx_outs: outputs}) do
    input_sum = Enum.reduce(inputs, 0, fn input, acc -> acc + Input.value(input) end)
    output_sum = Enum.reduce(outputs, 0, fn output, acc -> acc + output.amount end)

    fee = input_sum - output_sum

    cond do
      fee < 0 -> {:error, :negative_fee}
      # We do not wanna process txs without fees for now
      fee == 0 -> {:error, :empty_fee}
      fee > 0 -> fee
    end
  end

  # Check bytes if its segwit
  defp is_segwit(<<0x00, 0x01, tx_bin::binary>>), do: {true, tx_bin}

  # Not a segwit tx
  defp is_segwit(tx_bin) when is_binary(tx_bin), do: {false, tx_bin}

  @doc """
  ## LEGACY
  Computes the signature hash (z) for a transaction input.

  ## Parameters
    - tx: Transaction (%Tx{}).
    - input_index: Index of the input to sign.

  ## Returns
    - integer() with the signature hash.
    - {:error, reason} if invalid.
  """
  def sig_hash(
        %__MODULE__{
          version: version,
          tx_ins: inputs,
          tx_outs: outputs,
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
      |> Enum.map_join(fn {inp, i} ->
        # if the input index is ht one we're signing
        script_pubkey =
          if i == input_index do
            # If the RedeemScript (p2sh script) was passed in -> that's the ScriptSig
            # otherwise the previous tx's ScriptPubkey is the ScriptSig
            Input.script_pubkey(inp)
          else
            # Otherwise, the ScriptSig is nil
            nil
          end

        new_input = Input.new(inp.prev_tx, inp.prev_index, script_pubkey, inp.sequence, :legacy)
        Input.serialize(new_input)
      end)

    signature = signature <> inputs_signatures
    signature = signature <> encode_varint(length(outputs))

    serialized_outputs =
      Enum.reduce(outputs, "", fn output, acc ->
        acc <> Output.serialize(output)
      end)

    signature = signature <> serialized_outputs
    signature = signature <> MathUtils.int_to_little_endian(locktime, 4)
    signature = signature <> MathUtils.int_to_little_endian(@sighash_all, 4)
    CryptoUtils.double_hash256(signature)
  end

  @doc """
  Verifies the signature of a single input within a transaction.

  ## Parameters
    - tx: The transaction (%Tx{}).
    - input_index: The index of the input to verify.

  ## Returns
    - `true` if the signature is valid.
    - `false` otherwise.
  """
  def verify_input(%__MODULE__{tx_ins: inputs} = tx, input_index)
      when is_integer(input_index) and
             is_list(inputs) and length(inputs) > 0 do
    # Get the relevant input
    input = Enum.at(inputs, input_index)
    # Grab the previous ScriptPubKey
    script_pubkey =
      Input.script_pubkey(input) |> Base.decode16!(case: :mixed)

    # Get the signature hash(z)
    # Pass the redeemScript ot the sig_hash method
    z =
      case input.type do
        :segwit ->
          BIP143.sig_hash_bip143_p2wpkh(tx, input_index, script_pubkey)

        :legacy ->
          sig_hash(tx, input_index)
      end

    # Combined the current ScriptSig and the previous ScriptPubkey
    {_unread_bin, script_pubkey} = script_pubkey |> Script.parse()
    combined = Script.add(input.script_sig, script_pubkey)
    # evaluate the combined script
    Script.evaluate(combined, z)
  end

  @doc """
  Verifies the entire transaction by checking its fee and all input signatures.

  ## Parameters
    - tx: The transaction (%Tx{}).

  ## Returns
    - `true` if the transaction is valid.
    - `false` otherwise.
  """
  def verify(%__MODULE__{tx_ins: inputs} = tx) when is_list(inputs) and length(inputs) > 0 do
    case fee(tx) do
      {:error, _reason} ->
        false

      _ ->
        inputs
        |> Enum.with_index()
        |> Enum.all?(fn {_input, i} -> verify_input(tx, i) end)
    end
  end

  @doc """
  Computes the raw hash of the transaction (used for Tx ID).
  This involves serializing, double SHA256 hashing, and reversing bytes (little-endian).

  ## Parameters
    - tx: The transaction (%Tx{}).

  ## Returns
    - binary() representing the transaction hash.
  """
  def hash(%__MODULE__{} = tx) do
    tx
    |> serialize()
    |> CryptoUtils.hash256()
    |> CryptoUtils.hash256()
    |> :binary.bin_to_list()
    |> Enum.reverse()
    |> :binary.list_to_bin()
  end

  @doc """
  Computes the human-readable transaction ID (hex-encoded, little-endian hash).

  ## Parameters
    - tx: The transaction (%Tx{}).

  ## Returns
    - String with the lowercase hex ID.
  """
  def id(%__MODULE__{} = tx) do
    tx |> hash |> Base.encode16(case: :lower)
  end

  def serialize(tx, type \\ :legacy) when is_struct(tx, __MODULE__) do
    case type do
      :legacy -> serialize_legacy(tx)
      :segwit -> serialize_segwit(tx)
      _ -> {:error, "Type #{inspect(type)} not supported"}
    end
  end

  @doc """
  Returns the byte serialization of the transaction in Bitcoin wire format.

  ## Parameters
    - tx: The transaction (%Tx{}).

  ## Returns
    - binary() with the serialized transaction.
  """
  def serialize_legacy(%__MODULE__{
        version: version,
        tx_ins: tx_ins,
        tx_outs: tx_outs,
        locktime: locktime
      })
      when is_integer(version) and is_list(tx_ins) and length(tx_ins) > 0 and is_list(tx_outs) and
             length(tx_outs) > 0 and is_integer(locktime) do
    # Serialize version
    result = MathUtils.int_to_little_endian(version, 4)
    # Encode varint on the number of inputs
    result = result <> encode_varint(length(tx_ins))

    # Serialize each input
    serialized_inputs =
      Enum.map_join(tx_ins, fn inp ->
        Input.serialize(inp)
      end)

    result = result <> serialized_inputs <> encode_varint(length(tx_outs))

    serialized_outputs =
      Enum.map_join(tx_outs, fn out ->
        Output.serialize(out)
      end)

    result <> serialized_outputs <> MathUtils.int_to_little_endian(locktime, 4)
  end

  def serialize_segwit(%__MODULE__{
        version: version,
        tx_ins: tx_ins,
        tx_outs: tx_outs,
        locktime: locktime,
        witnesses: witnesses
      })
      when is_integer(version) and is_list(tx_ins) and length(tx_ins) > 0 and is_list(tx_outs) and
             length(tx_outs) > 0 and is_integer(locktime) and length(witnesses) > 0 and
             length(tx_ins) == length(witnesses) do
    # Serialize version
    result = MathUtils.int_to_little_endian(version, 4)
    # Encode varint on the number of inputs
    result = result <> <<0x00, 0x01>>
    result = result <> encode_varint(length(tx_ins))

    # Serialize each input
    serialized_inputs =
      Enum.map_join(tx_ins, fn inp ->
        Input.serialize(inp)
      end)

    result = result <> serialized_inputs <> encode_varint(length(tx_outs))

    serialized_outputs =
      Enum.map_join(tx_outs, fn out ->
        Output.serialize(out)
      end)

    result = result <> serialized_outputs

    serialized_witnesses =
      Enum.map_join(witnesses, fn witness_stack ->
        stack_varint = encode_varint(length(witness_stack))

        items =
          Enum.map_join(witness_stack, fn item ->
            encode_varint(byte_size(item)) <> item
          end)

        stack_varint <> items
      end)

    result <>
      serialized_witnesses <> MathUtils.int_to_little_endian(locktime, 4)
  end

  @doc """
  Signs a specific input in the transaction using a private key.
  It calculates the signature hash, signs it, and constructs the
  ScriptSig (assuming P2PKH for now).
  ## Parameters
    - tx: The transaction (%Tx{}).
    - input_index: The index of the input to sign.
    - private_key: The %PrivateKey{} to use for signing.

  ## Returns
    - `{boolean, %Tx{}}` where the boolean indicates if verification passed,
      and the %Tx{} is the updated transaction with the new ScriptSig.
  """
  def sign_input(
        %__MODULE__{tx_ins: inputs} = tx,
        input_index,
        %PrivateKey{} = private_key,
        sender_pubkey
      )
      when is_integer(input_index) and is_binary(sender_pubkey) do
    # Check for input type
    current_input = Enum.at(inputs, input_index)

    z =
      case current_input.type do
        :segwit ->
          BIP143.sig_hash_bip143_p2wpkh(
            tx,
            input_index,
            sender_pubkey |> CryptoUtils.hash160()
          )

        :legacy ->
          sig_hash(tx, input_index)
      end

    der = PrivateKey.sign(private_key, z) |> Signature.der()
    # The signature is a combination of the DER signature and the hash type
    sig = der <> :binary.encode_unsigned(@sighash_all, :big)
    sec = private_key.point |> Secp256Point.compressed_sec()

    case current_input.type do
      :segwit ->
        witness_stack_for_this_input = [sig, sec]

        updated_witnesses_list =
          List.replace_at(tx.witnesses, input_index, witness_stack_for_this_input)

        updated_tx_for_segwit = %__MODULE__{
          tx
          | witnesses: updated_witnesses_list
        }

        # Add real verify here
        {verify_input(updated_tx_for_segwit, input_index), updated_tx_for_segwit}

      :legacy ->
        # The scriptSig of a p2pkh has two elements, the signature and SEC format public key
        script_sig = Script.new([sig, sec])

        updated_inputs =
          Enum.with_index(tx.tx_ins)
          |> Enum.map(fn {input, i} ->
            if i == input_index do
              %Input{input | script_sig: script_sig}
            else
              input
            end
          end)

        updated = %__MODULE__{tx | tx_ins: updated_inputs}
        {verify_input(updated, input_index), updated}
    end
  end

  @doc """
  Checks if the transaction is a coinbase transaction.
  A coinbase transaction is the first transaction in a block, created by miners.
  It has exactly one input, and that input has specific characteristics.

  ## Parameters
    - tx: The transaction (%Tx{}).

  ## Returns
    - `true` if it's a coinbase transaction.
    - `false` otherwise.
  """
  def is_coinbase(%__MODULE__{tx_ins: inputs}) when is_list(inputs) and length(inputs) == 1 do
    [only_input] = inputs
    Input.is_coinbase(only_input)
  end

  # Any transaction not having exactly one input cannot be a coinbase.
  def is_coinbase(%__MODULE__{}) do
    false
  end

  @doc """
  Extracts the block height from a coinbase transaction's ScriptSig.
  According to BIP0034, the first element pushed in a coinbase ScriptSig
  must be the block height, encoded as a Script NOP (push number).

  ## Parameters
    - tx: The coinbase transaction (%Tx{}).

  ## Returns
    - integer() (block height) if it's a valid coinbase.
    - `nil` otherwise.
  """
  def coinbase_height(%__MODULE__{tx_ins: inputs} = tx)
      when is_list(inputs) and length(inputs) > 0 do
    if is_coinbase(tx) do
      [only_input] = inputs
      [coin_base_height | _] = only_input.script_sig.cmds
      MathUtils.little_endian_to_int(coin_base_height)
    else
      nil
    end
  end

  def sign(%__MODULE__{tx_ins: inputs} = initial_tx, %PrivateKey{} = pk, %BIP32.Xpub{
        public_key: public_key
      }) do
    0..(length(inputs) - 1)
    |> Enum.reduce(initial_tx, fn i, tx ->
      {{:ok}, updated_tx} = sign_input(tx, i, pk, public_key)
      updated_tx
    end)
  end
end
