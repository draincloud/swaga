require Logger

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
    MathUtils.int_to_little_endian(amount, 8) <> Script.serialize(script_pubkey)
  end

  def parse(s) do
    <<raw_amount::binary-size(8), rest::binary>> = s
    amount = MathUtils.little_endian_to_int(raw_amount)
    {rest2, script_pubkey} = Script.parse(rest)
    {rest2, %TxOut{amount: amount, script_pubkey: script_pubkey}}
  end
end
