defmodule BitcoinNodeTest do
  use ExUnit.Case
  @moduletag :skip

  test "handshake" do
    node = BitcoinNode.new(~c"ns343680.ip-94-23-21.eu", 8333)
    :ok = BitcoinNode.handshake(node)
  end
end
