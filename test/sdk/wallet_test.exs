defmodule Sdk.WalletTest do
  require Logger
  use ExUnit.Case
  require IEx
  alias Sdk.Wallet

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
end
