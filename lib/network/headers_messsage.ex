require Logger

defmodule HeadersMessage do
  @enforce_keys [:blocks]
  defstruct [:blocks]
  def command, do: "headers"

  def new(blocks) do
    %HeadersMessage{blocks: blocks}
  end

  def parse(serialized) when is_binary(serialized) do
    {num_headers, rest} = Tx.read_varint(serialized)

    {blocks, _bin} =
      Enum.reduce(1..num_headers, {[], rest}, fn _, {acc, bin_to_read} ->
        <<block_header::binary-size(80), rest_stream::binary>> = bin_to_read
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
