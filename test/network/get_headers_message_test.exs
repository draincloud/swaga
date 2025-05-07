defmodule GetHeadersMessageTest do
  use ExUnit.Case

  test "test serialize" do
    {:ok, block_hex} =
      Base.decode16("0000000000000000001237f46acddf58578a37e213d2a6edc4884a2fcad05ba3",
        case: :lower
      )

    gh = GetHeadersMessage.new(block_hex)

    assert GetHeadersMessage.serialize(gh) |> Base.encode16(case: :lower) ==
             "7f11010001a35bd0ca2f4a88c4eda6d213e2378a5758dfcd6af437120000000000000000000000000000000000000000000000000000000000000000000000000000000000"
  end
end
