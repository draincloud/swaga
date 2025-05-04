require Logger
import Bitwise

defmodule Block do
  @enforce_keys [
    :version,
    :prev_block,
    :merkle_root,
    :timestamp,
    :bits,
    :nonce
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
    :bits,
    # This number is what is changed by miners when looking for proof-of-work
    :nonce
  ]

  def new(
        version,
        prev_block,
        merkle_root,
        timestamp,
        bits,
        nonce
      ) do
    %Block{
      version: version,
      prev_block: prev_block,
      merkle_root: merkle_root,
      timestamp: timestamp,
      bits: bits,
      nonce: nonce
    }
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

    %Block{
      version: MathUtils.little_endian_to_int(version),
      # From little endian
      prev_block: Helpers.reverse_binary(prev_block),
      # From little endian
      merkle_root: Helpers.reverse_binary(merkle_root),
      timestamp: MathUtils.little_endian_to_int(timestamp),
      bits: bits,
      nonce: nonce
    }
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
  def target(%Block{bits: bits}) do
    # last byte is exponent
    <<rest_bits::binary-size(byte_size(bits) - 1), exponent>> = bits
    #    Logger.debug("bits #{inspect(Base.encode16()}")
    # the first three bytes are the coefficient in lttle endian
    coefficient = MathUtils.little_endian_to_int(rest_bits)
    # the formula is:
    # coefficient * 256**(exponent-3)
    coefficient * 256 ** (exponent - 3)
  end

  # difficulty = 0xffff × 256 ** (0x1d – 3) / target
  def difficulty(%Block{} = block) do
    0xFFFF * 256 ** (0x1D - 3) / target(block)
  end

  def check_pow(%Block{} = block) do
    proof = block |> hash |> Helpers.reverse_binary() |> MathUtils.little_endian_to_int()
    target(block) > proof
  end
end
