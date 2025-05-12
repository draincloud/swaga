require Logger

@doc """
BIP0037 Bloom Filters
BIP0037 specifies Bloom filters in network communication. The information contained in a Bloom filter is:
1. The size of the bit field, or how many buckets there are. The size is specified in
bytes (8 bits per byte) and rounded up if necessary.
2. The number of hash functions.
3. A “tweak” to be able to change the Bloom filter slightly if it hits too many items.
4. The bit field that results from running the Bloom filter over the items of interest.
"""
defmodule BloomFilter do
  @bip37 0xFBA4C795

  @enforce_keys [:size, :bit_field, :function_count, :tweak]
  defstruct [:size, :bit_field, :function_count, :tweak]

  def new(size, function_count, tweak) do
    %BloomFilter{
      size: size,
      bit_field: List.duplicate(0, size * 8),
      function_count: function_count,
      tweak: tweak
    }
  end

  def filter_bytes(%BloomFilter{bit_field: bit_field}) do
    MerkleBlock.bit_field_to_bytes(bit_field)
  end

  def add(%BloomFilter{bit_field: bit_field, function_count: function_count, tweak: tweak}, item) do
    0..(function_count - 1)
    |> Enum.reduce([], fn x, acc ->
      seed = x * @bip37 + tweak
      #      h =
    end)
  end

  def calculate(item_list, bit_field_size) when is_list(item_list) do
    bit_field = List.duplicate(0, 10)

    Enum.reduce(item_list, bit_field, fn item, acc ->
      index_bit = CryptoUtils.double_hash256(item) |> rem(bit_field_size)
      List.replace_at(acc, index_bit, 1)
    end)
  end
end
