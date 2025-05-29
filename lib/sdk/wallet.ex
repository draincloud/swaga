defmodule Sdk.Wallet do
  def generate_mnemonic() do
    entropy = :crypto.strong_rand_bytes(16)
    <<checksum::size(4), _::bitstring>> = CryptoUtils.hash256(entropy)
    combined_bits = <<entropy::bitstring, checksum::size(4)>>
    # Divide your 132-bit sequence into 12 groups, each containing 11 bits.
    case Binary.BitSplitter.split(combined_bits, 11) do
      {:ok, bit_groups} ->
        word_indices =
          Enum.map(bit_groups, fn bit ->
            <<word_index::integer-size(11)>> = bit
            word_index
          end)

        wordlist = BIP39.Wordlist.wordlist()

        Enum.map(word_indices, fn i ->
          Enum.at(wordlist, i)
        end)

      {:error, reason} ->
        {:error, reason}
    end
  end
end
