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

  def new(prev_tx, prev_index) do
    #    script_sig = Script
    script_sig = 1
    new(prev_tx, prev_index, script_sig, 0xFFFFFFFF)
  end

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
    #    result = result + script_sig.serialize()
    result + MathUtils.int_to_little_endian(sequence, 4)
  end

  def parse(s) when is_binary(s) do
    <<prev_tx::binary-size(32), rest>> = Helpers.reverse_binary(s)
    <<prev_index::binary-size(4), rest>> = rest
    prev_index = MathUtils.little_endian_to_int(prev_index)
    script_sig = Script.parse(s)
    <<sequence::binary-size(4), rest>> = rest
    sequence = MathUtils.little_endian_to_int(sequence)
    %TxIn{prev_tx: prev_tx, prev_index: prev_index, script_sig: script_sig, sequence: sequence}
  end
end
