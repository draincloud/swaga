require Logger

defmodule GetDataMessageTest do
  use ExUnit.Case

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

  @tag :in_progress
  test "send getdata message" do
    last_block_hex =
      "00000000000538d5c2246336644f9a4956551afb44ba47278759ec55ea912e19"
      |> Base.decode16!(case: :lower)

    # FIX base 58 decode
    address = "12CnxFWVZq59tbsgoSn6TJWArWLoiJDRNk"
    h160 = Base58.decode(address)
    node = BitcoinNode.new(~c"ns343680.ip-94-23-21.eu", 8333)
    bloom_filter = BloomFilter.new(30, 5, 90210)
    bloom_filter = BloomFilter.add(bloom_filter, h160)
    :ok = BitcoinNode.handshake(node)

    {:ok} =
      BitcoinNode.send(node, BloomFilter.filterload(bloom_filter), GenericMessage, "filterload")

    start_block = last_block_hex
    get_headers = GetHeadersMessage.new(start_block)
    {:ok} = BitcoinNode.send(node, get_headers, GetHeadersMessage)
    headers = BitcoinNode.wait_for(node, [], HeadersMessage.command())
    getdata = GetDataMessage.new()
    %{blocks: blocks} = HeadersMessage.parse(headers.payload)
    Logger.debug("blocks #{inspect(blocks)}")

    data_message =
      Enum.reduce(blocks, getdata, fn block, acc ->
        true = Block.check_pow(block)
        Logger.debug("hash #{inspect(Block.hash(block) |> Base.encode16(case: :lower))}")
        GetDataMessage.add_data(acc, GetDataMessage.filtered_block_data_type(), Block.hash(block))
      end)

    Logger.debug("data_message #{inspect(data_message)}")
    {:ok} = BitcoinNode.send(node, data_message, GetDataMessage)
    headers = BitcoinNode.wait_for(node, [], MerkleBlock.command())
  end
end
