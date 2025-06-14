defmodule Transaction.Input do
  require IEx
  require Logger
  alias Binary.Common
  alias Sdk.RpcClient
  alias Transaction

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
          # Index of the output in the previous tx. Stored in big-endian
          prev_index: non_neg_integer(),
          # The unlocking script.
          script_sig: Script.t(),
          # Sequence number (default: 0xFFFFFFFF).
          sequence: non_neg_integer(),
          # :legacy, :segwit
          type: atom()
        }

  @enforce_keys [
    :prev_tx,
    :prev_index,
    :script_sig,
    :sequence,
    :type
  ]

  defstruct [
    :prev_tx,
    :prev_index,
    :script_sig,
    :sequence,
    :type
  ]

  @doc """
  Creates a new `TxIn` with default `script_sig` and `sequence`.

  Useful for creating inputs before signing, where the `script_sig`
  is initially empty and the sequence number is standard.
  """
  def new(prev_tx, prev_index) do
    %__MODULE__{
      prev_tx: prev_tx,
      prev_index: prev_index,
      script_sig: Script.new(),
      sequence: 0xFFFFFFFF,
      type: :legacy
    }
  end

  @doc """
  Creates a new `TxIn` with a specified `script_sig` and `sequence`.
  """
  def new(prev_tx, prev_index, script_sig, sequence, type) do
    %__MODULE__{
      prev_tx: prev_tx,
      prev_index: prev_index,
      script_sig: script_sig,
      sequence: sequence,
      type: type
    }
  end

  @doc """
  Serializes a `TxIn` into the Bitcoin wire format (binary).
  """
  def serialize(%__MODULE__{
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

    tx_in =
      new(
        prev_tx,
        prev_index,
        script_sig,
        sequence,
        :legacy
      )

    {rest4, tx_in}
  end

  @doc """
  Fetches the value (amount in satoshis) of the output this `TxIn` is spending.

  This requires fetching the full previous transaction, typically via an external
  service (`TxFetcher`). It returns `amount`.
  """
  def value(%{prev_tx: prev_tx, prev_index: index}) do
    rpc = RpcClient.new()
    prev_tx = if is_binary(prev_tx), do: Base.encode16(prev_tx), else: prev_tx

    outputs =
      case RpcClient.get_raw_transaction(rpc, prev_tx) do
        {:ok, tx} ->
          Map.get(tx, "result") |> Map.get("vout")

        reason ->
          {:error, reason}
      end

    Enum.at(outputs, index) |> Map.get("value") |> Common.convert_to_satoshis() |> trunc()
  end

  @doc """
  Fetches the `ScriptPubKey` of the output this `TxIn` is spending.

  This is necessary to verify the `script_sig`. It returns `script`
  """
  def script_pubkey(%__MODULE__{prev_tx: prev_tx, prev_index: prev_index}) do
    rpc = RpcClient.new()
    prev_tx = if is_binary(prev_tx), do: Base.encode16(prev_tx), else: prev_tx

    outputs =
      case RpcClient.get_raw_transaction(rpc, prev_tx) do
        {:ok, tx} ->
          IEx.pry()
          Map.get(tx, "result") |> Map.get("vout")

        reason ->
          {:error, reason}
      end

    Enum.at(outputs, prev_index) |> Map.get("scriptPubKey") |> Map.get("hex")
  end

  @doc """
  Checks if a `TxIn` is part of a coinbase transaction.

  Coinbase inputs have a `prev_tx` hash of all zeros and a `prev_index` of 0xFFFFFFFF.
  """
  def is_coinbase(%__MODULE__{prev_tx: prev_tx, prev_index: prev_index})
      when is_binary(prev_tx) and is_integer(prev_index) do
    cond do
      prev_index == 0xFFFFFFFF and prev_tx == :binary.copy(<<00>>, 32) -> true
      true -> false
    end
  end
end
