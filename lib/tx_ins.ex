defmodule TxIn do
  
  defimpl String.Chars, for: TxIn do
    def to_string(tx_in) do
      Kernel.inspect(tx_in)
    end
  end
end
