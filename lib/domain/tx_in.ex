defmodule TxIn do
  require Logger
  alias Binary.Common

  @moduledoc """
  Represents a single input in a Bitcoin transaction.

  Each `TxIn` points to a specific output from a previous transaction (`prev_tx`, `prev_index`).
  It includes a `script_sig` which provides the "proof" (usually a signature and public key)
  required to spend the referenced output, and a `sequence` number (often used for locktime or RBF).
  """
  # Define the structure of a Transaction Input.
  @type t :: %__MODULE__{
          # Hash of the previous transaction (32 bytes).
          prev_tx: binary(),
          # Index of the output in the previous tx.
          prev_index: non_neg_integer(),
          # The unlocking script.
          script_sig: Script.t(),
          # Sequence number (default: 0xFFFFFFFF).
          sequence: non_neg_integer()
        }

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

  @doc """
  Creates a new `TxIn` with default `script_sig` and `sequence`.

  Useful for creating inputs before signing, where the `script_sig`
  is initially empty and the sequence number is standard.
  """
  def new(prev_tx, prev_index) do
    %TxIn{
      prev_tx: prev_tx,
      prev_index: prev_index,
      script_sig: Script.new(),
      sequence: 0xFFFFFFFF
    }
  end

  @doc """
  Creates a new `TxIn` with a specified `script_sig` and `sequence`.
  """
  def new(prev_tx, prev_index, script_sig, sequence) do
    %TxIn{prev_tx: prev_tx, prev_index: prev_index, script_sig: script_sig, sequence: sequence}
  end

  @doc """
  Serializes a `TxIn` into the Bitcoin wire format (binary).
  """
  def serialize(%TxIn{
        prev_tx: prev_tx,
        prev_index: prev_index,
        script_sig: script_sig,
        sequence: sequence
      })
      when is_binary(prev_tx) and is_integer(prev_index) and is_struct(script_sig, Script) and
             is_integer(sequence) do
    # Serialize prev_tx, little_endian
    prev_tx_le = Common.reverse_binary(prev_tx)
    # Serialize prev_index, 4 bytes
    prev_index_le = MathUtils.int_to_little_endian(prev_index, 4)
    script_sig_bin = Script.serialize(script_sig)
    seq_le = MathUtils.int_to_little_endian(sequence, 4)
    <<prev_tx_le::binary, prev_index_le::binary, script_sig_bin::binary, seq_le::binary>>
  end

  @doc """
  Parses a `TxIn` from its serialized binary format.

  Returns a tuple containing the remaining binary and the parsed `TxIn`.
  """
  def parse(s) when is_binary(s) do
    <<prev_tx_raw::binary-size(32), rest::binary>> = s
    prev_tx = Common.reverse_binary(prev_tx_raw)

    <<prev_index_raw::binary-size(4), rest2::binary>> = rest
    prev_index = MathUtils.little_endian_to_int(prev_index_raw)

    {rest3, script_sig} = Script.parse(rest2)

    <<sequence::binary-size(4), rest4::binary>> = rest3
    sequence = MathUtils.little_endian_to_int(sequence)

    {rest4,
     %TxIn{prev_tx: prev_tx, prev_index: prev_index, script_sig: script_sig, sequence: sequence}}
  end

  @doc """
  Fetches the value (amount in satoshis) of the output this `TxIn` is spending.

  This requires fetching the full previous transaction, typically via an external
  service (`TxFetcher`). It returns `amount`.
  """
  def value(%{prev_tx: prev_tx, prev_index: index}, testnet) do
    %{tx_outs: outputs} = fetch_tx(prev_tx, testnet)
    Enum.at(outputs, index).amount
  end

  @doc """
  Fetches the `ScriptPubKey` of the output this `TxIn` is spending.

  This is necessary to verify the `script_sig`. It returns `script`
  """
  def script_pubkey(%TxIn{prev_tx: prev_tx, prev_index: prev_index}, testnet) do
    %{tx_outs: outputs} = fetch_tx(prev_tx, testnet)
    Enum.at(outputs, prev_index).script_pubkey
  end

  @doc """
  Checks if a `TxIn` is part of a coinbase transaction.

  Coinbase inputs have a `prev_tx` hash of all zeros and a `prev_index` of 0xFFFFFFFF.
  """
  def is_coinbase(%TxIn{prev_tx: prev_tx, prev_index: prev_index})
      when is_binary(prev_tx) and is_integer(prev_index) do
    cond do
      prev_index == 0xFFFFFFFF and prev_tx == :binary.copy(<<00>>, 32) -> true
      true -> false
    end
  end

  #  Internal helper to fetch a transaction using its hash.
  #  Handles hex encoding and calls the `TxFetcher`. Returns Tx.t()
  #  or `{:error, reason}`.
  defp fetch_tx(hash, testnet) when is_binary(hash) do
    hex = Base.encode16(hash)
    TxFetcher.fetch(hex, testnet)
  end

  defp fetch_tx(hash, _testnet) do
    {:error, {:invalid_hash_type, hash}}
  end
end
