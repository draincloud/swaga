require Logger

defmodule BloomFilterTest do
  use ExUnit.Case

  @tag :in_progress
  test "bloom filter" do
    bit_field = BloomFilter.calculate(["hello world", "goodbye"], 10)
    assert [0, 0, 1, 0, 0, 0, 0, 0, 0, 1] == bit_field
  end

  test "bloom filter examples" do
    bit_field = BloomFilter.new(10, 5, 99)
    assert [0, 0, 1, 0, 0, 0, 0, 0, 0, 1] == bit_field
  end
end
