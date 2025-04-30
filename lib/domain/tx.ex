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

  #  def id(tx) do
  #    hash(tx)
  #  end
  #
  #  def hash(tx) do
  #     :crypto.hash(:sha256, serialize(tx))
  #     |> :binary.bin_to_list
  #     |> Enum.reverse
  #     |> :binary.list_to_bin
  #  end

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

  def parse(serialized_tx) when is_binary(serialized_tx) do
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
      testnet: false
    }
  end

  def fee(%{tx_ins: inputs, tx_outs: outputs}, testnet) do
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

  #  def serialize(%Tx{
  #        version: version,
  #        tx_ins: tx_ins,
  #        tx_outs: tx_outs,
  #        locktime: locktime,
  #        testnet: testnet
  #      }) do
  #    result = MathUtils.int_to_little_endian()
  #    result = result + encode_varint(length(tx_ins))
  #    result = result + Enum.reduce(tx_ins, fn x, acc -> x + acc end)
  #    result = result + encode_varint(length(tx_outs))
  #    result = result + Enum.reduce(tx_outs, fn x, acc -> x + acc end)
  #    result + MathUtils.int_to_little_endian(locktime, 4)
  #  end
end
