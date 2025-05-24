require Logger

defmodule HeadersMessageTest do
  use ExUnit.Case
  @moduletag :skip
  test "download the headers, check their proof-of-work and validate the block header difficulty" do
    genesis_block = Block.parse(Block.genesis())
    genesis_hash = Block.hash(genesis_block)
    expected_bits = Block.lowest_bits()
    node = BitcoinNode.new(~c"ns343680.ip-94-23-21.eu", 8333)
    :ok = BitcoinNode.handshake(node)

    get_headers = GetHeadersMessage.new(genesis_hash)

    {:ok} = BitcoinNode.send(node, get_headers, GetHeadersMessage)

    %HeadersMessage{blocks: blocks} =
      BitcoinNode.wait_for(node, [], "headers").payload |> HeadersMessage.parse()

    Enum.each(blocks, fn b ->
      true = Block.check_pow(b)
      assert b.bits == expected_bits
    end)

    # We get exactly 2000 blocks
    assert 2000 == length(blocks)
  end

  test "parse" do
    hex_msg =
      Base.decode16!(
        "0200000020df3b053dc46f162a9b00c7f0d5124e2676d47bbe7c5d0793a500000000000000ef445fef2ed495c275892206ca533e7411907971013ab83e3b47bd0d692d14d4dc7c835b67d8001ac157e670000000002030eb2540c41025690160a1014c577061596e32e426b712c7ca00000000000000768b89f07044e6130ead292a3f51951adbd2202df447d98789339937fd006bd44880835b67d8001ade09204600",
        case: :lower
      )

    %{blocks: blocks} = HeadersMessage.parse(hex_msg)
    assert length(blocks) == 2
  end
end
