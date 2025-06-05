defmodule Sdk.WalletTest do
  require Logger
  use ExUnit.Case
  require IEx
  alias Sdk.Wallet
  alias TxIn
  alias TxOut
  alias Sdk.RpcClient

  test "mnemonic generate" do
    mnemonic_list = Wallet.generate_mnemonic()
    assert is_list(mnemonic_list) and length(mnemonic_list) == 12
  end

  test "from mnemonic" do
    mnemonic = "dentist save glimpse fossil govern tag gesture beach angle carbon head comic"
    wallet = Wallet.from_mnemonic(mnemonic)

    assert wallet.seed ==
             "8831b9adfb820d72c9419dc84fe3214c5511300ed00f971903883e9ff46d4b3e531e41972271af110e2ca542860944dc5f4723d134ac7c4379f17083a70c0909"
  end

  test "from seed" do
    seed =
      "8831b9adfb820d72c9419dc84fe3214c5511300ed00f971903883e9ff46d4b3e531e41972271af110e2ca542860944dc5f4723d134ac7c4379f17083a70c0909"

    wallet = Wallet.from_seed(seed)

    assert wallet.seed ==
             "8831b9adfb820d72c9419dc84fe3214c5511300ed00f971903883e9ff46d4b3e531e41972271af110e2ca542860944dc5f4723d134ac7c4379f17083a70c0909"
  end

  test "new" do
    %{seed: seed} = Wallet.new()
    assert is_binary(seed) && byte_size(seed) > 0
  end

  test "derived xprv from seed" do
    seed =
      "000102030405060708090a0b0c0d0e0f"

    wallet = Wallet.from_seed(seed)

    derived = Wallet.derive_private_key(wallet, "m/0H")

    assert derived.seed ==
             "000102030405060708090a0b0c0d0e0f"

    assert derived.xprv.encoded_xprv ==
             "xprv9uHRZZhk6KAJC1avXpDAp4MDc3sQKNxDiPvvkX8Br5ngLNv1TxvUxt4cV1rGL5hj6KCesnDYUhd7oWgT11eZG7XnxHrnYeSvkzY7d2bhkJ7"
  end

  test "derived xpub from seed" do
    seed =
      "000102030405060708090a0b0c0d0e0f"

    wallet = Wallet.from_seed(seed)

    derived = Wallet.derive_public_key(wallet, 10)

    assert derived.xpub.encoded_xpub ==
             "xpub699i5FJZk4LBShBF6fp2dpzux483SVoUBhap4HgB814SdbwLpmQocsetjhBURGRiZYTvnN91U2gXkZwEPxQMJLAVdTCMqYNdPGimoC8TD8D"
  end

  test "get address" do
    seed =
      "000102030405060708090a0b0c0d0e0f"

    {:ok, address} =
      Wallet.from_seed(seed)
      |> Wallet.derive_private_key("m/0/0/0/0")
      |> Wallet.generate_address()

    assert address == "19DQYeqNSEmbK5RQHEffK3zMoVDVRmzTzC"
  end

  test "wallet generate address mainnet bech32" do
    sender =
      Wallet.from_seed("4ac2c2d606a110b150ff849fef221cc71643a03517ca7fda185a8ca1d410c7d4")

    {:ok, sender_address} = Wallet.generate_address(sender, type: :bech32, network: :mainnet)
    assert "bc1qfxj53saudlgqc8n0nkwqpq83qgvlwdpzyuljq7" == sender_address
  end

  @tag :in_progress
  test "use wallet and create transaction" do
    seed_wallet =
      Wallet.from_seed("4ac2c2d606a110b150ff849fef221cc71643a03517ca7fda185a8ca1d410c7d4")

    sender = Wallet.derive_private_key(seed_wallet, "m/84'/1'/0'/0/0")
    receiver = Wallet.derive_private_key(seed_wallet, "m/44'/1'/0'/0/0")
    #    Logger.debug("sender #{inspect(sender.xprv.encoded_xprv)}")
    #    Logger.debug("sender #{inspect(sender.xprv.private_key |> Base.encode16())}")
    #    Logger.debug("sender #{inspect(sender.xpub.public_key |> Base.encode16())}")

    #    Logger.debug("receiver #{inspect(receiver.xprv.encoded_xprv)}")
    {:ok, sender_address} = Wallet.generate_address(sender, type: :bech32, network: :testnet)
    {:ok, receiver_address} = Wallet.generate_address(receiver, type: :base58, network: :testnet)
    Logger.debug("sender_address #{inspect(sender_address)}")
    Logger.debug("receiver #{inspect(receiver_address)}")
    assert "tb1qrxjer6fnga3d7ksll524dwsxkacqssla3umzu3" == sender_address
    assert "mkjykgkDYWePhvofKMkLqq3AEwcTYDZP3s" == receiver_address

    prev_tx =
      "cc05853720254f9f44f151ad25ed5b0391aecae39c4642681b9d3e3a97e62212"
      |> Base.decode16!(case: :lower)

    prev_index = 0
    tx_in = TxIn.new(prev_tx, prev_index, Script.new([]), 0xFFFFFFFF, :segwit)

    change_h160 = Base58.decode(receiver_address)
    change_script = Script.p2pkh_script(change_h160)
    change_amount = trunc(0.00008 * 100_000_000)
    change_output = TxOut.new(change_amount, change_script)

    target_amount = trunc(0.00001 * 100_000_000)
    target_h160 = Base58.decode(receiver_address)
    target_script = Script.p2pkh_script(target_h160)
    target_output = TxOut.new(target_amount, target_script)

    private_key = sender.xprv.private_key |> PrivateKey.new()
    Logger.debug("receiver #{inspect(sender.xprv.private_key |> Integer.to_string(16))}")
    IEx.pry()
    # We need to sign tx for every input
    tx = Tx.new(1, [tx_in], [change_output, target_output], 0) |> Tx.sign(private_key)
    Logger.debug("Signed tx #{inspect(tx)}")
    Logger.debug("Private key #{inspect(private_key.secret)}")
    tx_build = Tx.serialize(tx, :segwit) |> Base.encode16(case: :lower)
    rpc = RpcClient.new()
    Logger.debug(tx_build)

    # continue need to create segwit tx, the way to serialize tx should be different
    tx_result =
      case RpcClient.send_raw_transaction(rpc, tx_build) do
        {:ok, tx} ->
          Logger.debug(tx)
          Map.get(tx, "result") |> Map.get("hex")

        error ->
          Logger.debug("#{inspect(error)}")
          {:error}
      end
  end
end

# 020000000001017316c3b54aa6af69999afe393e3e33cd81a5c8914e2e1afd72a1ca9223b098eb0100000000ffffffff02401f0000000000001976a914394f412584e5407cc9591165b5b832ef3bb40e2988ace8030000000000001976a914394f412584e5407cc9591165b5b832ef3bb40e2988ac 0247304402202329d1f18cddffd442b2606ec782771a115585ee9e462ed7d83a72efc25d6c7e022000b41a499dfb99dca6f6851772424740b9e39c9c0dda96f239e9d4f307559230 012103d2ea744829ee2ec2b84e5a384f0316483598f0db27e9c01fc37e0190088be28e00000000
# 010000000001017316c3b54aa6af69999afe393e3e33cd81a5c8914e2e1afd72a1ca9223b098eb0100000000ffffffff02401f0000000000001976a914394f412584e5407cc9591165b5b832ef3bb40e2988ace8030000000000001976a914394f412584e5407cc9591165b5b832ef3bb40e2988ac 02483045022100a7c73d36744d4f2cdf955376f6442ad08c47c1c0295fcb6848e1252a74263ac80220519210b7d7dc3d105cd0ed57ad9840c74a7a33149fd00971cdc0b212ca8a3a3f 012103d2ea744829ee2ec2b84e5a384f0316483598f0db27e9c01fc37e0190088be28e00000000
