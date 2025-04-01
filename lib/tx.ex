defmodule Tx do
  @enforce_keys [
    :version,
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

  defimpl String.Chars, for:  Tx do
    def to_string(self) do
      # TODO
      Kernel.inspect(self)
    end
  end

  def id(tx) do
    hash(tx)
  end

  def hash(tx) do
    # :crypto.hash(:sha256, serialize(tx))
    # |> :binary.bin_to_list
    # |> Enum.reverse
    # |> :binary.list_to_bin
  end

  def parse(serialization) do
    <<four_bites::binary-size(8), _resp::binary>> = serialization
    :logger.debug("#{four_bites}")
    %Tx{
      version:  MathUtils.little_endian_to_int(Base.decode16! four_bites),
    }
  end
end
