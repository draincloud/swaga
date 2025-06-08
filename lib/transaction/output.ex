defmodule Transaction.Output do
  @moduledoc """
  Represents a single output in a Bitcoin transaction.

  Each `TxOut` defines an amount of satoshis and a `script_pubkey` (locking script).
  The `script_pubkey` specifies the conditions that must be met (usually providing
  a signature) to spend these satoshis in a future transaction.
  """
  @type t :: %__MODULE__{
          # Amount in satoshis (8 bytes).
          amount: non_neg_integer(),
          # The locking script.
          script_pubkey: Script.t()
        }
  @enforce_keys [
    :amount,
    :script_pubkey
  ]

  defstruct [
    :amount,
    :script_pubkey
  ]

  @doc """
  Creates a new `TxOut`.
  """
  def new(amount, script_pubkey) when is_integer(amount) and is_struct(script_pubkey, Script) do
    %__MODULE__{amount: amount, script_pubkey: script_pubkey}
  end

  @doc """
  Serializes a `TxOut` into the Bitcoin wire format (binary).
  """
  def serialize(%{amount: amount, script_pubkey: script_pubkey})
      when is_integer(amount) and is_struct(script_pubkey, Script) do
    MathUtils.int_to_little_endian(amount, 8) <> Script.serialize(script_pubkey)
  end

  @doc """
  Parses a `TxOut` from its serialized binary format.

  Returns a tuple containing the parsed `TxOut` and the remaining binary,
  or an error tuple.
  """
  def parse(s) when is_binary(s) do
    <<raw_amount::binary-size(8), rest::binary>> = s
    amount = MathUtils.little_endian_to_int(raw_amount)
    {rest2, script_pubkey} = Script.parse(rest)
    {rest2, %__MODULE__{amount: amount, script_pubkey: script_pubkey}}
  end
end
