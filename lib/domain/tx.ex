require Logger

defmodule Tx do
  @sighash_all 1

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

  def new(
        version,
        tx_ins,
        tx_outs,
        locktime,
        testnet
      ) do
    %Tx{
      version: version,
      tx_ins: tx_ins,
      tx_outs: tx_outs,
      locktime: locktime,
      testnet: testnet
    }
  end

  def command, do: "tx"

  def read_varint(<<0xFD, rest::binary>>) do
    <<two_bytes::binary-size(2), rest2::binary>> = rest
    {MathUtils.little_endian_to_int(two_bytes), rest2}
  end

  def read_varint(<<0xFE, rest::binary>>) do
    <<four_bytes::binary-size(4), rest2::binary>> = rest
    {MathUtils.little_endian_to_int(four_bytes), rest2}
  end

  def read_varint(<<0xFF, rest::binary>>) do
    <<eight_bytes::binary-size(8), rest2::binary>> = rest
    {MathUtils.little_endian_to_int(eight_bytes), rest2}
  end

  def read_varint(<<prefix, rest::binary>>) do
    {prefix, rest}
  end

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
    raise "Integer too large"
  end

  def parse(serialized_tx, testnet \\ false) when is_binary(serialized_tx) do
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
      tx_ins: inputs,
      tx_outs: Enum.reverse(outputs),
      locktime: locktime,
      testnet: testnet
    }
  end

  def fee(%{tx_ins: inputs, tx_outs: outputs}, testnet \\ false) do
    input_sum =
      Enum.reduce(inputs, 0, fn input, acc -> acc + TxIn.value(input, testnet) end)

    input_sum - Enum.reduce(outputs, 0, fn output, acc -> acc + output.amount end)
  end

  # Checking the signature.
  # A transaction has at least one signature per input.
  # We use op_code OP_CHECKSIG, but the hard part is getting the signature hash to validate it.
  # That's why we modify the transaction before signing it, we compute a different signature hash for each input.
  #######
  #  Returns the integer representation of the hash that needs to get
  #  signed for index input_index
  def sig_hash(
        %Tx{
          version: version,
          tx_ins: inputs,
          tx_outs: outputs,
          testnet: testnet,
          locktime: locktime
        },
        input_index
      ) do
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
