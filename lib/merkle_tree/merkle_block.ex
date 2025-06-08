defmodule MerkleBlock do
  import Bitwise
  alias Transaction

  @moduledoc """
  Represents a Merkle Block, used by Simplified Payment Verification (SPV) clients.

  A Merkle Block contains the block header and a partial Merkle tree that proves
  the inclusion of specific transactions within the block, without needing to
  download the entire block.
  """
  @type t :: %__MODULE__{
          version: integer(),
          # 32-byte hash of the previous block header
          prev_block: binary(),
          # 32-byte root of the Merkle tree
          merkle_root: binary(),
          # Unix epoch time
          timestamp: non_neg_integer(),
          # 4-byte target difficulty
          bits: binary(),
          # 4-byte nonce used in mining
          nonce: binary(),
          # Total number of transactions in the full block
          number_of_txs: non_neg_integer(),
          # Number of hashes in the `hashes` list
          number_of_hashes: non_neg_integer(),
          # List of 32-byte hashes in the partial Merkle tree
          hashes: [binary()],
          # A bitfield indicating the structure of the partial Merkle tree
          flag_bits: binary()
        }

  @enforce_keys [
    :version,
    :prev_block,
    :merkle_root,
    :timestamp,
    :bits,
    :nonce,
    :number_of_txs,
    :number_of_hashes,
    :hashes,
    :flag_bits
  ]

  defstruct [
    :version,
    :prev_block,
    :merkle_root,
    :timestamp,
    :bits,
    :nonce,
    :number_of_txs,
    :number_of_hashes,
    :hashes,
    :flag_bits
  ]

  @doc """
  Returns the command identifier for Merkle Blocks, used in the Bitcoin network protocol.
  """
  def command, do: "merkleblock"

  @doc """
  Creates a new `MerkleBlock`.
  """
  def new(
        version,
        prev_block,
        merkle_root,
        timestamp,
        bits,
        nonce,
        number_of_txs,
        number_of_hashes,
        hashes,
        flag_bits
      ) do
    %MerkleBlock{
      version: version,
      prev_block: prev_block,
      merkle_root: merkle_root,
      timestamp: timestamp,
      bits: bits,
      nonce: nonce,
      number_of_txs: number_of_txs,
      number_of_hashes: number_of_hashes,
      hashes: hashes,
      flag_bits: flag_bits
    }
  end

  @doc """
  Parses a `MerkleBlock` from its serialized binary format.
  """
  def parse(serialized_block) when is_binary(serialized_block) do
    <<version::binary-size(4), prev_block::binary-size(32), merkle_root::binary-size(32),
      timestamp::binary-size(4), bits::binary-size(4), nonce::binary-size(4),
      number_of_txs::binary-size(4), number_of_hashes::binary-size(1),
      rest::binary>> = serialized_block

    txs_count = MathUtils.little_endian_to_int(number_of_txs)
    # We read the number of hashes, and all is left is hashes and flags
    {hashes_count, _} = Transaction.read_varint(number_of_hashes)
    <<hashes::binary-size(32 * hashes_count), flag_bytes::binary>> = rest

    {parsed_hashes, _} =
      Enum.reduce(1..hashes_count, {[], hashes}, fn _, {acc, bin} ->
        <<hash::binary-size(32), rest::binary>> = bin
        {acc ++ [hash |> Binary.Common.reverse_binary()], rest}
      end)

    {flags_count, bin_flags} = Transaction.read_varint(flag_bytes)

    <<flags::binary-size(flags_count), _::binary>> = bin_flags

    new(
      MathUtils.little_endian_to_int(version),
      Binary.Common.reverse_binary(prev_block),
      Binary.Common.reverse_binary(merkle_root),
      MathUtils.little_endian_to_int(timestamp),
      bits,
      nonce,
      txs_count,
      number_of_hashes,
      parsed_hashes,
      flags
    )
  end

  @doc """
  Given a list of bytes (integers 0..255), returns a flat list of bits
  (0 or 1) for each byte, least-significant bit first.
  """
  def bytes_to_bit_field(bytes) when is_list(bytes) do
    bytes
    |> Enum.flat_map(&byte_to_bits/1)
  end

  # Convert a single byte into its 8 bits
  defp byte_to_bits(byte) when is_integer(byte) and byte in 0..255 do
    for i <- 0..7 do
      # Shift right by i, then mask off all but the lowest bit
      byte >>> i &&& 1
    end
  end

  @doc """
  Given a flat list of bits (0 or 1) whose length is divisible by 8,
  packs each group of 8 bits (LSB first) into a byte and returns a binary.
  """
  def bit_field_to_bytes(bit_field) when rem(length(bit_field), 8) != 0 do
    raise ArgumentError, "bit_field does not have a length that is divisible by 8"
  end

  def bit_field_to_bytes(bit_field) do
    bit_field
    # 1. Chunk into sublists of 8 bits each
    |> Enum.chunk_every(8)
    # 2. For each 8-bit chunk, build a single byte
    |> Enum.map(&bits_chunk_to_byte/1)
    # 3. Turn the list of byte-integers into a binary
    |> :erlang.list_to_binary()
  end

  # Helper: turn [b0, b1, …, b7] into one integer 0..255
  defp bits_chunk_to_byte(bits) do
    bits
    |> Enum.with_index()
    |> Enum.reduce(0, fn
      {1, idx}, acc -> acc ||| 1 <<< idx
      {_, _}, acc -> acc
    end)
  end
end
