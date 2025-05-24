defmodule BIP32.Seed do
  require IEx
  def from_mnemonic(mnemonic, passphrase \\ "")

  def from_mnemonic(mnemonic, passphrase) when is_list(mnemonic) do
    with :ok <- check_mnemonic(mnemonic),
         :ok <- entropy_extraction(mnemonic) do
      generate_seed(mnemonic, passphrase)
    else
      {:error, reason} -> {:error, reason}
    end
  end

  def from_mnemonic(mnemonic_str, passphrase) when is_binary(mnemonic_str) do
    mnemonic = String.split(mnemonic_str, " ")
    from_mnemonic(mnemonic, passphrase)
  end

  defp check_mnemonic(mnemonic) when is_list(mnemonic) do
    wordlist = BIP39.Wordlist.wordlist()

    for word <- mnemonic do
      true = Enum.member?(wordlist, word)
    end

    :ok
  end

  defp entropy_extraction(mnemonic) when is_list(mnemonic) do
    wordlist = BIP39.Wordlist.wordlist()

    mnemonic_indices =
      Enum.map(mnemonic, fn m ->
        # Check if m exists in wordlist
        index = Enum.find_index(wordlist, &(&1 == m))
        true = is_integer(index)
        :binary.encode_unsigned(index, :big) |> pad_to_11_bits
      end)

    combined =
      Enum.reduce(mnemonic_indices, <<>>, fn <<a, b::size(3)>>, acc ->
        # The binary type requires segments to have sizes that are multiples of 8 bits
        # Use bitstring  modifier if you need non-byte-aligned sizes.
        <<acc::bitstring, a::size(8), b::size(3)>>
      end)

    # For now we only accept 12 word mnemonic, which should be 132 bits in total
    # For next upgrade: 24 words (264 bits)
    <<entropy::bitstring-size(128), checksum::bitstring-size(4)>> = combined
    true = validate_checksum(entropy, checksum)
    :ok
  end

  defp generate_seed(mnemonic, passphrase) when is_list(mnemonic) do
    mnemonic_str = mnemonic |> Enum.join(" ") |> :unicode.characters_to_nfkd_binary()
    salt = "mnemonic#{passphrase}" |> :unicode.characters_to_nfkd_binary()
    # default digest is sha512
    case Pbkdf2.Base.hash_password(mnemonic_str, salt,
           format: :hex,
           length: 64,
           rounds: 2048
         ) do
      seed -> {:ok, seed}
    end
  end

  defp validate_checksum(entropy, checksum) when is_bitstring(checksum) do
    <<cs_bits::bitstring-size(4), _::bitstring>> = CryptoUtils.hash256(entropy)
    cs_bits == checksum
  end

  # each index must be represented as 11 bit
  defp pad_to_11_bits(bin) when bit_size(bin) < 11 do
    <<0::3, bin::bitstring>>
  end

  defp pad_to_11_bits(bin) when bit_size(bin) > 11 do
    <<_::5, rest::11>> = bin
    <<rest::11>>
  end

  defp pad_to_11_bits(bin) do
    bin
  end
end
