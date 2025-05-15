require Logger

defmodule GetHeadersMessage do
  require IEx
  @enforce_keys [:version, :num_hashes, :start_block, :end_block]
  defstruct [:version, :num_hashes, :start_block, :end_block]
  def command(), do: "getheaders"

  def new(start_block) do
    %GetHeadersMessage{
      version: 70015,
      num_hashes: 1,
      start_block: start_block,
      end_block: :binary.copy(<<0x00>>, 32)
    }
  end

  def new(version, num_hashes, start_block, end_block) do
    %GetHeadersMessage{
      version: version,
      num_hashes: num_hashes,
      start_block: start_block,
      end_block: end_block
    }
  end

  def serialize(%GetHeadersMessage{
        version: version,
        num_hashes: num_hashes,
        start_block: start_block,
        end_block: end_block
      }) do
    header_version = MathUtils.int_to_little_endian(version, 4)
    header_num_hashes = Tx.encode_varint(num_hashes)
    start_block = Helpers.reverse_binary(start_block) |> Helpers.pad_binary(32)
    end_block = Helpers.reverse_binary(end_block) |> Helpers.pad_binary(32)
    header_version <> header_num_hashes <> start_block <> end_block
    #    IEx.pry()
  end

  def parse(serialized) when is_binary(serialized) do
    {num_headers, rest} = Tx.read_varint(serialized)

    {blocks, _bin} =
      Enum.reduce(0..num_headers, {[], rest}, fn _header, acc ->
        <<block_header::binary-size(80), rest_stream::binary>> = rest
        parsed = Block.parse(block_header)
        {num_txs, rest} = Tx.read_varint(rest_stream)

        # the number of transactions is always 0
        if num_txs != 0 do
          raise "Number of transactions not equal to 0, received #{inspect(num_txs)}"
        end

        {acc ++ [parsed], rest}
      end)

    new(blocks)
  end
end
