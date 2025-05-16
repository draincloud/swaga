require Logger

defmodule BloomFilterTest do
  use ExUnit.Case

  test "bloom filter" do
    bit_field = BloomFilter.calculate(["hello world", "goodbye"], 10)
    assert [0, 0, 1, 0, 0, 0, 0, 0, 0, 1] == bit_field
  end

  test "bloom filter examples" do
    %{bit_field: bit_field} = BloomFilter.new(10, 5, 99)
    assert List.duplicate(0, 80) == bit_field
  end

  test "bloom filter add" do
    bloom_filter = BloomFilter.new(10, 5, 99)
    item = "Hello World"
    updated_filter = BloomFilter.add(bloom_filter, item)
    expected_bits = "0000000a080000000140"

    assert expected_bits ==
             BloomFilter.filter_bytes(updated_filter.bit_field) |> Base.encode16(case: :lower)

    item = "Goodbye!"
    updated_filter = BloomFilter.add(updated_filter, item)
    expected_bits = "4000600a080000010940"

    assert expected_bits ==
             BloomFilter.filter_bytes(updated_filter.bit_field) |> Base.encode16(case: :lower)
  end

  test "filterload" do
    bloom_filter = BloomFilter.new(10, 5, 99)
    item = "Hello World"
    updated_filter = BloomFilter.add(bloom_filter, item)
    item = "Goodbye!"
    updated_filter = BloomFilter.add(updated_filter, item)
    expected_bits = "0a4000600a080000010940050000006300000001"

    assert expected_bits ==
             updated_filter
             |> BloomFilter.filterload()
             |> GenericMessage.serialize()
             |> Base.encode16(case: :lower)
  end
end
