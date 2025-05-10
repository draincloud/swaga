# Merkle Block is used for SPV-clients
defmodule MerkleBlock do
  @enforce_keys [
    :version,
    :prev_block,
    :merkle_root,
    :timestamp,
    :bits,
    :nonce,
    :number_of_txs,
    :number_of_hashes,
    :hashes,
    :flag_bits
  ]

  defstruct [
    :version,
    :prev_block,
    :merkle_root,
    :timestamp,
    :bits,
    :nonce,
    # Indicates how many leaves in particular merkle tree
    :number_of_txs,
    :number_of_hashes,
    :hashes,
    # Gives info about where the hashes go withing the merkle tree
    :flag_bits
  ]

  def new(
        version,
        prev_block,
        merkle_root,
        timestamp,
        bits,
        nonce,
        number_of_txs,
        number_of_hashes,
        hashes,
        flag_bits
      ) do
    %Block{
      version: version,
      prev_block: prev_block,
      merkle_root: merkle_root,
      timestamp: timestamp,
      bits: bits,
      nonce: nonce,
      number_of_txs: number_of_txs,
      number_of_hashes: number_of_hashes,
      hashes: hashes,
      flag_bits: flag_bits
    }
  end

  def parse(serialized_block) when is_binary(serialized_block) do
    <<version::binary-size(4), prev_block::binary-size(32), merkle_root::binary-size(32),
      timestamp::binary-size(4), bits::binary-size(4), nonce::binary-size(4),
      number_of_txs::binary-size(4), number_of_hashes::binary-size(1),
      rest::binary>> = serialized_block

    txs_count = MathUtils.little_endian_to_int(number_of_txs)
    {hashes_count, rest} = Tx.read_varint(rest)
    <<hashes::binart-size(32 * hashes_count), flag_bits::binary>> = rest
  end

  def bytes_to_bit_field(bytes) do
    bytes
    |> Enum.reduce("", fn x, acc ->
      nil
    end)
  end
end
