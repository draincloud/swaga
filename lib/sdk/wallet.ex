defmodule Sdk.Wallet do
  require Logger
  @enforce_keys [:seed, :xprv]
  defstruct [:seed, :xprv, :xpub]
  alias BIP32.Seed
  alias Bech32

  @type t :: %__MODULE__{
          seed: binary()
        }

  def from_mnemonic(mnemonic) when is_binary(mnemonic) or is_list(mnemonic) do
    case Seed.from_mnemonic(mnemonic) do
      {:ok, seed} ->
        from_seed(seed)

      {:error, reason} ->
        Logger.error(reason)
        {:error, reason}
    end
  end

  def from_seed(seed) when is_binary(seed) do
    master_pk =
      BIP32.Xprv.new_master(seed)

    master_pub = BIP32.Xpub.from_xprv(master_pk)

    %__MODULE__{
      seed: seed,
      xprv: master_pk,
      xpub: master_pub
    }
  end

  def new() do
    generate_mnemonic() |> from_mnemonic
  end

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

  def derive_private_key(%__MODULE__{xprv: xprv} = wallet, path) do
    derived = BIP32.Xprv.derive(xprv, path)
    master_pub = BIP32.Xpub.from_xprv(derived)
    %{wallet | xprv: derived, xpub: master_pub}
  end

  def derive_public_key(%__MODULE__{xpub: xpub} = wallet, index) do
    derived = BIP32.Xpub.derive_child(xpub, index)
    %{wallet | xpub: derived}
  end

  def generate_address(%__MODULE__{xpub: xpub}, opts \\ []) do
    h160 = CryptoUtils.hash160(xpub.public_key)

    network = Keyword.get(opts, :network, :mainnet)
    type = Keyword.get(opts, :type, :base58)

    {prefix, hrp} =
      case network do
        :mainnet ->
          {<<0x00>>, "bc"}

        :testnet ->
          {<<0x6F>>, "tb"}

        _ ->
          {:error, "Invalid network"}
      end

    case type do
      :base58 ->
        Base58.encode_base58_checksum(prefix <> h160)

      :bech32 ->
        case Bech32.convert_bits(:binary.bin_to_list(h160), 8, 5, true) do
          {:ok, five_bit_groups} ->
            # Now call encode with the list of 5-bit integers
            # Pass :bech32 as encoding_type
            Bech32.encode(hrp, five_bit_groups, :bech32)

          {:error, reason} ->
            Logger.error("Failed to convert bits for Bech32 encoding: #{inspect(reason)}")
            {:error, {:bit_conversion_failed, reason}}
        end

      _ ->
        {:error, "Type not supported #{type}"}
    end
  end

  #  def create_transaction(inputs, outputs, fee_rate, change_address) do
  #  end

  #  def get_utxos(address)
  #  def sign_transaction(unsigned_tx, private_keys_for_inputs)
  #  def broadcast_transaction(signed_tx)
end
