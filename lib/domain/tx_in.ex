require Logger

defmodule TxIn do
  @enforce_keys [
    :prev_tx,
    :prev_index,
    :script_sig,
    :sequence
  ]

  defstruct [
    :prev_tx,
    :prev_index,
    :script_sig,
    :sequence
  ]

  defimpl String.Chars, for: TxIn do
    def to_string(tx_in) do
      Kernel.inspect(tx_in)
    end
  end

  #  def new(prev_tx, prev_index) do
  #    script_sig = 1
  #    new(prev_tx, prev_index, script_sig, 0xFFFFFFFF)
  #  end

  def new(prev_tx, prev_index, script_sig, sequence) do
    %TxIn{prev_tx: prev_tx, prev_index: prev_index, script_sig: script_sig, sequence: sequence}
  end

  def serialize(%TxIn{
        prev_tx: prev_tx,
        prev_index: prev_index,
        script_sig: _script_sig,
        sequence: sequence
      }) do
    result = :binary.bin_to_list(prev_tx) |> Enum.reverse()
    result = result + MathUtils.int_to_little_endian(prev_index, 4)
    result + MathUtils.int_to_little_endian(sequence, 4)
  end

  def parse(s) when is_binary(s) do
    <<prev_tx_raw::binary-size(32), rest::binary>> = s
    prev_tx = Helpers.reverse_binary(prev_tx_raw)

    <<prev_index_raw::binary-size(4), rest2::binary>> = rest
    prev_index = MathUtils.little_endian_to_int(prev_index_raw)

    {rest3, script_sig} = Script.parse(rest2)

    <<sequence::binary-size(4), rest4::binary>> = rest3
    sequence = MathUtils.little_endian_to_int(sequence)

    {rest4,
     %TxIn{prev_tx: prev_tx, prev_index: prev_index, script_sig: script_sig, sequence: sequence}}
  end

  defp fetch_tx(hash, testnet) do
    hex = Base.encode16(hash)
    TxFetcher.fetch(hex, testnet)
  end

  def value(%{prev_tx: prev_tx, prev_index: index}, true) do
    %{tx_outs: outputs} = fetch_tx(prev_tx, true)
    Enum.at(outputs, index).amount
  end

  def value(%{prev_tx: prev_tx, prev_index: index}, false) do
    %{tx_outs: outputs} = fetch_tx(prev_tx, false)
    Enum.at(outputs, index).amount
  end
end
