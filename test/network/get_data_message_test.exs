require Logger

defmodule GetDataMessageTest do
  require IEx
  use ExUnit.Case
  @moduletag :skip

  test "test serialize" do
    hex_msg =
      "020300000030eb2540c41025690160a1014c577061596e32e426b712c7ca00000000000000030000001049847939585b0652fba793661c361223446b6fc41089b8be00000000000000"

    gh = GetDataMessage.new()

    block1 =
      Base.decode16!(
        "00000000000000cac712b726e4326e596170574c01a16001692510c44025eb30",
        case: :lower
      )

    updated_message =
      GetDataMessage.add_data(gh, GetDataMessage.filtered_block_data_type(), block1)

    block2 =
      Base.decode16!(
        "00000000000000beb88910c46f6b442312361c6693a7fb52065b583979844910",
        case: :lower
      )

    updated_message = GetDataMessage.add_data(updated_message, 3, block2)
    assert hex_msg == updated_message |> GetDataMessage.serialize() |> Base.encode16(case: :lower)
  end

  test "send getdata message" do
    # 895752
    last_block =
      "00000000000000000001f1621527881a88c844988e22a8c1e913f48e733e3018"
      |> Base.decode16!(case: :lower)

    # 895759
    start_block =
      "00000000000000000000646bf8e642b975087e4520b54544b83c316a7af1ce67"
      |> Base.decode16!(case: :lower)

    address = "1NyLs3xAfq913ugwaZpZ8ygVZoXDSJ7JrN"
    h160 = Base58.decode(address)
    node = BitcoinNode.new(~c"ns343680.ip-94-23-21.eu", 8333)
    bf = BloomFilter.new(30, 5, 90210)
    bloom_filter = BloomFilter.add(bf, h160)

    :ok = BitcoinNode.handshake(node)

    {:ok} =
      BitcoinNode.send(node, BloomFilter.filterload(bloom_filter), GenericMessage, "filterload")

    get_headers = GetHeadersMessage.new(70015, 1, start_block, last_block)
    {:ok} = BitcoinNode.send(node, get_headers, GetHeadersMessage)
    headers = BitcoinNode.wait_for(node, [], HeadersMessage.command())
    getdata = GetDataMessage.new()
    %{blocks: blocks} = HeadersMessage.parse(headers.payload)

    data_message =
      Enum.reduce(blocks, getdata, fn block, acc ->
        true = Block.check_pow(block)
        GetDataMessage.add_data(acc, GetDataMessage.filtered_block_data_type(), Block.hash(block))
      end)

    {:ok} = BitcoinNode.send(node, data_message, GetDataMessage)
    merkle = BitcoinNode.wait_for(node, [], Tx.command())
    Logger.debug("data_message #{inspect(merkle)}")
  end
end
