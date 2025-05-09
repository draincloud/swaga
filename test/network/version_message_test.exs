defmodule VersionMessageTest do
  use ExUnit.Case

  test "serialize" do
    nonce = :binary.copy(<<0x00>>, 8)

    want =
      "7f11010000000000000000000000000000000000000000000000000000000000000000000000ffff00000000208d000000000000000000000000000000000000ffff00000000208d0000000000000000182f70726f6772616d6d696e67626974636f696e3a302e312f0000000000"

    ver_msg =
      VersionMessage.new(
        70015,
        0,
        0,
        0,
        <<0x00, 0x00, 0x00, 0x00>>,
        8333,
        0,
        <<0x00, 0x00, 0x00, 0x00>>,
        8333,
        nonce
      )

    assert want == Base.encode16(VersionMessage.serialize(ver_msg), case: :lower)
  end
end
