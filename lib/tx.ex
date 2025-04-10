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

  defimpl String.Chars, for: Tx do
    def to_string(self) do
      # TODO
      Kernel.inspect(self)
    end
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

  def read_varint(<<0xFD, _::binary>>) do
    MathUtils.little_endian_to_int(Base.decode16!(0xFD))
  end

  def read_varint(<<0xFE, _::binary>>) do
    MathUtils.little_endian_to_int(Base.decode16!(0xFE))
  end

  def read_varint(<<0xFF, _::binary>>) do
    MathUtils.little_endian_to_int(Base.decode16!(0xFF))
  end

  def read_varint(<<prefix, _::binary>>) do
    prefix
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
    <<four_bytes::binary-size(8), rest::binary>> = serialized_tx
    num_inputs = read_varint(rest)
    inputs = []
    for input <- 0..num_inputs do
      parsed_input = TxIn.parse(input)
    end
    %Tx{
      version: MathUtils.little_endian_to_int(Base.decode16!(four_bytes)),
      tx_ins: inputs
    }
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
