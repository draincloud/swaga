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

  test "use wallet and create transaction" do
    sender =
      Wallet.from_seed("4ac2c2d606a110b150ff849fef221cc71643a03517ca7fda185a8ca1d410c7d4")

    #    Logger.debug("sender #{inspect(sender.xprv.encoded_xprv)}")
    #    Logger.debug("sender #{inspect(sender.xprv.private_key |> Base.encode16())}")
    #    Logger.debug("sender #{inspect(sender.xpub.public_key |> Base.encode16())}")

    receiver =
      Wallet.from_seed(
        "562c06543d700ced1e2e8c05d04cc2aa32579fc753cb43bb0e03dec40e9ee83f48c8b729507572ab25ef9e6b4736c0d30e6ce5de78df163328e4d70b52cba28a"
      )

    #    Logger.debug("receiver #{inspect(receiver.xprv.encoded_xprv)}")
    {:ok, sender_address} = Wallet.generate_address(sender, type: :bech32, network: :testnet)
    {:ok, receiver_address} = Wallet.generate_address(receiver, type: :base58, network: :testnet)
    Logger.debug("sender_address #{inspect(sender_address)}")
    Logger.debug("receiver #{inspect(receiver_address)}")
    assert "tb1qfxj53saudlgqc8n0nkwqpq83qgvlwdpzw6ypmd" == sender_address
    assert "mthgYuwnJUnjqNVgjSMnoRysj1bkXJwSvq" == receiver_address

    prev_tx =
      "eb98b02392caa172fd1a2e4e91c8a581cd333e3e39fe9a9969afa64ab5c31673"
      |> Base.decode16!(case: :lower)

    prev_index = 1
    tx_in = TxIn.new(prev_tx, prev_index)

    change_h160 = Base58.decode(receiver_address)
    change_script = Script.p2pkh_script(change_h160)
    change_amount = trunc(0.00008 * 100_000_000)
    change_output = TxOut.new(change_amount, change_script)

    target_amount = trunc(0.00001 * 100_000_000)
    target_h160 = Base58.decode(receiver_address)
    target_script = Script.p2pkh_script(target_h160)
    target_output = TxOut.new(target_amount, target_script)

    tx = Tx.new(1, [tx_in], [change_output, target_output], 0, true)
    tx_build = Tx.serialize(tx) |> Base.encode16(case: :lower)
    id = Tx.id(tx)
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
