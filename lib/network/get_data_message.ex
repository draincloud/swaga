defmodule GetDataMessage do
  defstruct [:data]

  @tx_data_type 1
  @block_data_type 2
  @filtered_block_data_type 3
  @compact_block_data_type 4

  def tx_data_type, do: @tx_data_type
  def block_data_type, do: @block_data_type
  def filtered_block_data_type, do: @filtered_block_data_type
  def compact_block_data_type, do: @compact_block_data_type

  def command, do: "getdata"

  def new() do
    %GetDataMessage{data: []}
  end

  def add_data(%GetDataMessage{data: data}, data_type, identifier) do
    %GetDataMessage{data: data ++ [{data_type, identifier}]}
  end

  @doc """
  The number of items as a varint specifies how many items we want. Each item has a
  type. A type value of 1 is a transaction, 2 is a normal block, 3
  is a Merkle block, and 4 is a compact block .
  """
  def serialize(%GetDataMessage{data: data}) do
    number_of_items = Tx.encode_varint(length(data))

    Enum.reduce(data, number_of_items, fn {data_type, identifier}, acc ->
      acc <>
        MathUtils.int_to_little_endian(data_type, 4) <>
        Helpers.reverse_binary(identifier)
    end)
  end
end
