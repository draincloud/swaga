require Logger
# Merkle Block is used for SPV-clients
defmodule MerkleBlock do
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
    # Indicates how many leaves in particular merkle tree
    :number_of_txs,
    :number_of_hashes,
    :hashes,
    # Gives info about where the hashes go withing the merkle tree
    :flag_bits
  ]

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

  def parse(serialized_block) when is_binary(serialized_block) do
    <<version::binary-size(4), prev_block::binary-size(32), merkle_root::binary-size(32),
      timestamp::binary-size(4), bits::binary-size(4), nonce::binary-size(4),
      number_of_txs::binary-size(4), number_of_hashes::binary-size(1),
      rest::binary>> = serialized_block

    txs_count = MathUtils.little_endian_to_int(number_of_txs)
    # We read the number of hashes, and all is left is hashes and flags
    {hashes_count, _} = Tx.read_varint(number_of_hashes)
    Logger.debug("hashes_count #{inspect(hashes_count)}")
    Logger.debug("hashes_flags #{inspect(byte_size(rest))}")
    <<hashes::binary-size(32 * hashes_count), flag_bytes::binary>> = rest

    {parsed_hashes, _} =
      Enum.reduce(1..hashes_count, {[], hashes}, fn _, {acc, bin} ->
        <<hash::binary-size(32), rest::binary>> = bin
        {acc ++ [hash |> Helpers.reverse_binary()], rest}
      end)

    {flags_count, bin_flags} = Tx.read_varint(flag_bytes)

    <<flags::binary-size(flags_count), _::binary>> = bin_flags

    new(
      MathUtils.little_endian_to_int(version),
      Helpers.reverse_binary(prev_block),
      Helpers.reverse_binary(merkle_root),
      MathUtils.little_endian_to_int(timestamp),
      bits,
      nonce,
      txs_count,
      number_of_hashes,
      parsed_hashes,
      flags
    )
  end

  import Bitwise

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
