require Logger
import Bitwise

defmodule Block do
  @moduledoc """
  Represents a Bitcoin block, including its header (version, prev_block, merkle_root, timestamp, bits, nonce)
  and transaction hashes. Provides functions for serialization, parsing, proof-of-work validation,
  and difficulty calculation per the Bitcoin protocol.
  """
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

  @type t :: %__MODULE__{
          version: non_neg_integer(),
          prev_block: <<_::256>>,
          merkle_root: <<_::256>>,
          timestamp: non_neg_integer(),
          bits: <<_::32>>,
          nonce: <<_::32>>,
          tx_hashes: [<<_::256>>]
        }

  @doc """
  Creates a new block with the given fields.

  ## Parameters
    - version: Block version (non-negative integer).
    - prev_block: 32-byte previous block hash.
    - merkle_root: 32-byte Merkle root hash.
    - timestamp: Unix timestamp (non-negative integer).
    - bits: 4-byte difficulty target.
    - nonce: 4-byte nonce.
    - tx_hashes: List of 32-byte transaction hashes (default: []).

  ## Returns
    - %Block{} on success.
    - Raises ArgumentError on invalid inputs.
  """
  def new(
        version,
        prev_block,
        merkle_root,
        timestamp,
        bits,
        nonce,
        tx_hashes \\ []
      )
      when is_integer(version) and version >= 0 and
             is_binary(prev_block) and byte_size(prev_block) == 32 and
             is_binary(merkle_root) and byte_size(merkle_root) == 32 and
             is_integer(timestamp) and timestamp >= 0 and
             is_binary(bits) and byte_size(bits) == 4 and
             is_binary(nonce) and byte_size(nonce) == 4 and
             is_list(tx_hashes) do
    case Enum.all?(tx_hashes, &(is_binary(&1) and byte_size(&1) == 32)) do
      false ->
        {:error, :invalid_tx_hashes}

      true ->
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
  end

  @doc """
  Validates the block's Merkle root against its transaction hashes.

  Returns true if the computed Merkle root matches the stored root, false otherwise.
  """
  def validate_merkle_root(%Block{merkle_root: root, tx_hashes: tx_hashes})
      when is_binary(root) and byte_size(root) == 32 and is_list(tx_hashes) and tx_hashes != [] do
    # we need to reverse hashes because of little-endian
    calculated_root =
      tx_hashes |> Enum.map(&Helpers.reverse_binary/1) |> MerkleTree.merkle_root()

    Helpers.reverse_binary(root) == calculated_root
  end

  def validate_merkle_root(_), do: false

  @doc """
  Serializes a block header into an 80-byte binary per Bitcoin protocol.

  ## Returns
    - 80-byte binary representing the block header.
  """
  def serialize(%Block{
        version: version,
        prev_block: prev_block,
        merkle_root: merkle_root,
        timestamp: timestamp,
        bits: bits,
        nonce: nonce
      })
      when is_integer(version) and is_binary(prev_block) and byte_size(prev_block) == 32 and
             is_binary(merkle_root) and byte_size(merkle_root) == 32 and
             is_integer(timestamp) and is_binary(bits) and byte_size(bits) == 4 and
             is_binary(nonce) and byte_size(nonce) == 4 do
    encoded_version = MathUtils.int_to_little_endian(version, 4)
    # Reverse, because we store it as little-endian
    encoded_prev_block = Helpers.reverse_binary(prev_block)
    merkle_root = Helpers.reverse_binary(merkle_root)
    timestamp = MathUtils.int_to_little_endian(timestamp, 4)

    encoded_version <> encoded_prev_block <> merkle_root <> timestamp <> bits <> nonce
  end

  @doc """
  Parses an 80-byte serialized block header into a %Block{} struct.

  ## Returns
    - %Block{} on success.
    - {:error, :reason} 
  """
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

  def parse(_), do: {:error, :invalid_block_header_size}

  @doc """
  Computes the double SHA-256 hash of the block header, reversed for Bitcoin's little-endian convention.

  ## Returns
    - 32-byte binary hash.
  """
  def hash(%Block{} = block) do
    hash =
      serialize(block)
      |> CryptoUtils.double_hash256()
      |> :binary.encode_unsigned()
      |> Helpers.pad_binary(32)
      |> Helpers.reverse_binary()

    32 = byte_size(hash)
    hash
  end

  @doc """
  Checks if the block signals support for BIP-9 (soft fork signaling).
  """
  def bip9(%Block{version: version}) do
    version >>> 29 == 0b001
  end

  @doc """
  Checks if the block signals support for BIP-91 (SegWit activation).
  """
  def bip91(%Block{version: version}) do
    (version >>> 4 &&& 0b1) == 1
  end

  @doc """
  Checks if the block signals support for BIP-141 (SegWit).
  """
  def bip141(%Block{version: version}) do
    (version >>> 1 &&& 0b1) == 1
  end

  @doc """
  Converts a 4-byte bits field to a proof-of-work target (integer).

  ## Parameters
    - bits: 4-byte binary (3-byte coefficient + 1-byte exponent).

  ## Returns
    - Integer target.
  """
  def bits_to_target(bits) when is_binary(bits) and byte_size(bits) == 4 do
    # last byte is exponent
    <<rest_bits::binary-size(byte_size(bits) - 1), exponent>> = bits
    # the first three bytes are the coefficient in little endian
    coefficient = MathUtils.little_endian_to_int(rest_bits)
    # the formula is:
    # coefficient * 256**(exponent-3)
    coefficient * 256 ** (exponent - 3)
  end

  @doc """
  Converts an integer target to a 4-byte bits field.

  ## Returns
    - 4-byte binary.
  """
  def target_to_bits(target) when is_integer(target) and target > 0 do
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

  @doc """
  Calculates the block's difficulty based on its bits field.

  ## Returns
    - Float representing difficulty (0xFFFF * 256^(0x1D-3) / target).
  """
  def difficulty(%Block{bits: bits}) do
    0xFFFF * 256 ** (0x1D - 3) / bits_to_target(bits)
  end

  @doc """
  Checks if the block's hash satisfies the proof-of-work target.

  ## Returns
    - true if the hash is below the target, false otherwise.
  """
  def check_pow(%Block{bits: bits} = block) do
    proof = block |> hash |> Helpers.reverse_binary() |> MathUtils.little_endian_to_int()
    bits_to_target(bits) > proof
  end

  def max_target() do
    0xFFFF * 256 ** (0x1D - 3)
  end

  @doc """
  Calculates new bits for the next difficulty adjustment based on the previous bits
  and the time differential between 2016 blocks.

  ## Parameters
    - prev_bits: 4-byte binary of previous difficulty target.
    - time_diff: Time difference in seconds (non-negative integer).

  ## Returns
    - 4-byte binary of new bits.
  """
  def calculate_new_bits(prev_bits, time_diff)
      when is_binary(prev_bits) and byte_size(prev_bits) == 4 and
             is_integer(time_diff) and time_diff >= 0 do
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
    new_target = min(new_target, max_target())
    target_to_bits(round(new_target))
  end

  @doc """
  Returns the Bitcoin genesis block header
  """
  def genesis() do
    Base.decode16!(
      "0100000000000000000000000000000000000000000000000000000000000000000000003ba3edfd7a7b12b27ac72c3e67768f617fc81bc3888a51323a9fb8aa4b1e5e4a29ab5f49ffff001d1dac2b7c",
      case: :lower
    )
  end

  @doc """
  Returns the bits for the lowest difficulty (genesis block).
  """
  def lowest_bits() do
    Base.decode16!("ffff001d", case: :lower)
  end
end
