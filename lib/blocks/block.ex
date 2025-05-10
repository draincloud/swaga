require Logger
import Bitwise

defmodule Block do
  @two_weeks 1_209_600

  @enforce_keys [
    :version,
    :prev_block,
    :merkle_root,
    :timestamp,
    :bits,
    :nonce,
    :tx_hashes
  ]

  defstruct [
    :version,
    # All blocks have to point to a previous block
    :prev_block,
    # The Merkle root encodes all the ordered transactions in a 32-byte hash
    :merkle_root,
    # The timestamp is a Unix-style timestamp taking up 4 bytes.
    :timestamp,
    # Bits is a field that encodes the proof-of-work necessary in this block
    # bits is a 4-byte (32-bit) compact representation of the target threshold
    # that a block hash must be below to be considered valid.
    :bits,
    # This number is what is changed by miners when looking for proof-of-work
    :nonce,
    :tx_hashes
  ]

  def new(
        version,
        prev_block,
        merkle_root,
        timestamp,
        bits,
        nonce,
        tx_hashes \\ []
      ) do
    %Block{
      version: version,
      prev_block: prev_block,
      merkle_root: merkle_root,
      timestamp: timestamp,
      bits: bits,
      nonce: nonce,
      tx_hashes: tx_hashes
    }
  end

  def validate_merkle_root(%Block{merkle_root: root, tx_hashes: tx_hashes}) do
    # we need to reverse hashes because of little-endian
    calculated_root =
      tx_hashes |> Enum.map(fn x -> Helpers.reverse_binary(x) end) |> MerkleTree.merkle_root()

    Logger.debug(
      "root -> #{root |> Helpers.reverse_binary() |> Base.encode16(case: :lower)}, calc: #{inspect(calculated_root) |> Base.encode16(case: :lower)}"
    )

    Helpers.reverse_binary(root) == calculated_root
  end

  #  Returns the 80 byte block header
  def serialize(%Block{
        version: version,
        prev_block: prev_block,
        merkle_root: merkle_root,
        timestamp: timestamp,
        bits: bits,
        nonce: nonce
      }) do
    encoded_version = MathUtils.int_to_little_endian(version, 4)
    # Reverse, because we store it as little-endian
    encoded_prev_block = Helpers.reverse_binary(prev_block)
    merkle_root = Helpers.reverse_binary(merkle_root)

    timestamp = MathUtils.int_to_little_endian(timestamp, 4)
    encoded_version <> encoded_prev_block <> merkle_root <> timestamp <> bits <> nonce
  end

  # Block Headers have the fixed length (80 bytes)
  # Takes a byte stream and parses a block. Returns a Block object
  def parse(serialized_block)
      when is_binary(serialized_block) and byte_size(serialized_block) == 80 do
    <<version::binary-size(4), prev_block::binary-size(32), merkle_root::binary-size(32),
      timestamp::binary-size(4), bits::binary-size(4), nonce::binary-size(4)>> = serialized_block

    new(
      MathUtils.little_endian_to_int(version),
      Helpers.reverse_binary(prev_block),
      Helpers.reverse_binary(merkle_root),
      MathUtils.little_endian_to_int(timestamp),
      bits,
      nonce
    )
  end

  def parse(block) do
    raise "Size is not correct, expected 80, got #{inspect(byte_size(block))}"
  end

  def hash(%Block{} = block) do
    serialize(block)
    |> CryptoUtils.double_hash256()
    |> :binary.encode_unsigned()
    |> Helpers.reverse_binary()
  end

  def bip9(%Block{version: version}) do
    version >>> 29 == 001
  end

  def bip91(%Block{version: version}) do
    (version >>> 4 &&& 1) == 1
  end

  def bip141(%Block{version: version}) do
    (version >>> 1 &&& 1) == 1
  end

  # Returns the proof-of-work target based on the bits
  def bits_to_target(bits) when is_binary(bits) do
    # last byte is exponent
    <<rest_bits::binary-size(byte_size(bits) - 1), exponent>> = bits
    # the first three bytes are the coefficient in lttle endian
    coefficient = MathUtils.little_endian_to_int(rest_bits)
    # the formula is:
    # coefficient * 256**(exponent-3)
    coefficient * 256 ** (exponent - 3)
  end

  def target_to_bits(target) when is_integer(target) do
    # encode and get rid of leading 0's
    <<first_byte, _::binary>> =
      tx =
      :binary.encode_unsigned(target, :big) |> Helpers.remove_leading_zeros()

    # if the first bit is 1, we have to start with 00
    {coefficient, exponent} =
      if first_byte > 0x7F do
        # if the first bit is 1, we have to start with 00
        <<two_bytes::binary-size(2), _rest::binary>> = tx
        {<<0x00>> <> two_bytes, byte_size(tx) + 1}
      else
        # otherwise, we can show the first 3 bytes
        # exponent is the number of digits in base-256
        # coefficient is the first 3 digits of the base-256 number
        <<three_bytes::binary-size(3), _rest::binary>> = tx
        {three_bytes, byte_size(tx)}
      end

    # we've truncated the number after the first 3 digits of base-256
    Helpers.reverse_binary(coefficient) <> <<exponent>>
  end

  # difficulty = 0xffff × 256 ** (0x1d – 3) / target
  def difficulty(%Block{bits: bits}) do
    0xFFFF * 256 ** (0x1D - 3) / bits_to_target(bits)
  end

  def check_pow(%Block{bits: bits} = block) do
    proof = block |> hash |> Helpers.reverse_binary() |> MathUtils.little_endian_to_int()
    bits_to_target(bits) > proof
  end

  def max_target() do
    0xFFFF * 256 ** (0x1D - 3)
  end

  # Calculates the new bits given
  # a 2016-block time differential and the previous bits
  def calculate_new_bits(prev_bits, time_diff) do
    diff =
      cond do
        # if the time differential is greater than 8 weeks, set to 8 weeks
        time_diff > @two_weeks * 4 -> @two_weeks * 4
        # if the time differential is less than half a week, set to half a week
        time_diff < div(@two_weeks, 4) -> div(@two_weeks, 4)
        true -> time_diff
      end

    # the new target is the previous target * time differential / two weeks
    new_target = (bits_to_target(prev_bits) * diff) |> div(@two_weeks)

    max = max_target()

    new_target =
      if new_target > max do
        max
      else
        new_target
      end

    target_to_bits(new_target)
  end

  def genesis() do
    Base.decode16!(
      "0100000000000000000000000000000000000000000000000000000000000000000000003ba3edfd7a7b12b27ac72c3e67768f617fc81bc3888a51323a9fb8aa4b1e5e4a29ab5f49ffff001d1dac2b7c",
      case: :lower
    )
  end

  def lowest_bits() do
    Base.decode16!("ffff001d", case: :lower)
  end
end
