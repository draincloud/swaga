defmodule Binary.BitSplitterTest do
  alias Binary.BitSplitter
  use ExUnit.Case

  test "splits a binary into 2-bit chunks" do
    test_bin = <<0b10110100::8>>

    expected_chunks = [
      <<0b10::size(2)>>,
      <<0b11::size(2)>>,
      <<0b01::size(2)>>,
      <<0b00::size(2)>>
    ]

    assert BitSplitter.split(test_bin, 2) == {:ok, expected_chunks}
  end
end
