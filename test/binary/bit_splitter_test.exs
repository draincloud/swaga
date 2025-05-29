defmodule Binary.BitSplitterTest do
  use ExUnit.Case

  test "splits correctly" do
    test_bin = <<1, 2, 3, 4, 5, 6, 7, 8>>

    assert {:ok, [<<1, 2>>, <<3, 4>>, <<5, 6>>, <<7, 8>>]} ==
             Binary.BitSplitter.split(test_bin, 2)
  end
end
