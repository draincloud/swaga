defmodule TxOut do
  @enforce_keys [
    :amount,
    :script_pubkey
  ]

  defstruct [
    :amount,
    :script_pubkey
  ]

  def new(amount, script_pubkey) do
    %TxOut{amount: amount, script_pubkey: script_pubkey}
  end

  def serialize(%{amount: amount, script_pubkey: script_pubkey}) do
    result = MathUtils.int_to_little_endian(amount, 8)
    result + script_pubkey
  end
end
