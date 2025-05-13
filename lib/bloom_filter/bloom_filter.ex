require Logger

defmodule BloomFilter do
  require IEx
  import Bitwise

  # since erlang/elixir integers are variable-length we have to guarantee them
  # to be 32 or 64 bit long
  defmacrop mask_32(x), do: quote(do: unquote(x) &&& 0xFFFFFFFF)

  @doc """
  BIP0037 Bloom Filters
  BIP0037 specifies Bloom filters in network communication. The information contained in a Bloom filter is:
  1. The size of the bit field, or how many buckets there are. The size is specified in
  bytes (8 bits per byte) and rounded up if necessary.
  2. The number of hash functions.
  3. A “tweak” to be able to change the Bloom filter slightly if it hits too many items.
  4. The bit field that results from running the Bloom filter over the items of interest.
  """
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

  def filter_bytes(bit_field) do
    MerkleBlock.bit_field_to_bytes(bit_field)
  end

  def add(
        %BloomFilter{
          size: size,
          bit_field: bit_field,
          function_count: function_count,
          tweak: tweak
        } = filter,
        item
      ) do
    new_bits =
      0..(function_count - 1)
      |> Enum.reduce(bit_field, fn x, acc ->
        # BIP0037 spec seed is i*
        # We need to mask i32, as bitcoin implementation works with i32 max
        seed = (x * @bip37 + tweak) |> mask_32
        # get murmur
        h = Murmur.hash_x86_32(item, seed)
        # iex -S mix test --trace test/bloom_filter/bloom_filter_test.exs
        # IEx.pry()
        bit = h |> rem(size * 8)
        List.replace_at(acc, bit, 1)
      end)

    %{filter | bit_field: new_bits}
  end

  def calculate(item_list, bit_field_size) when is_list(item_list) do
    bit_field = List.duplicate(0, 10)

    Enum.reduce(item_list, bit_field, fn item, acc ->
      index_bit = CryptoUtils.double_hash256(item) |> rem(bit_field_size)
      List.replace_at(acc, index_bit, 1)
    end)
  end

  # Returns the generic message with "filterload"
  def filterload(
        %BloomFilter{
          size: size,
          bit_field: bit_field,
          function_count: function_count,
          tweak: tweak
        },
        flag \\ 1
      ) do
    payload =
      Tx.encode_varint(size) <>
        filter_bytes(bit_field) <>
        MathUtils.int_to_little_endian(function_count, 4) <>
        MathUtils.int_to_little_endian(tweak, 4) <>
        MathUtils.int_to_little_endian(flag, 1)

    GenericMessage.new("filterload", payload)
  end
end
