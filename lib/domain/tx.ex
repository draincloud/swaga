require Logger

defmodule Tx do
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
    inputs = []

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

  def fee(%{tx_ins: inputs, tx_outs: outputs} = tx, testnet) do
    input_sum =
      Enum.reduce(inputs, 0, fn input, acc -> acc = acc + TxIn.value(input, testnet) end)

    output_sum = Enum.reduce(outputs, 0, fn output, acc -> acc = acc + output.amount end)
    input_sum - output_sum
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
