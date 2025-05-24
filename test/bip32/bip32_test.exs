require Logger

defmodule BIP32.Test do
  require IEx
  use ExUnit.Case
  @seed "000102030405060708090a0b0c0d0e0f"

  #  https://github.com/bitcoin/bips/blob/master/bip-0032.mediawiki#test-vectors
  test "correct creation of master key" do
    seed = @seed |> Base.decode16!(case: :lower)

    %{chain_code: _chain_code, encoded_xprv: secret, depth: 0, child_number: 0, xpub: pubkey} =
      BIP32.Xprv.new_master(seed)

    assert secret ==
             "xprv9s21ZrQH143K3QTDL4LXw2F7HEK3wJUD2nW2nRk4stbPy6cq3jPPqjiChkVvvNKmPGJxWUtg6LnF5kejMRNNU3TGtRBeJgk33yuGBxrMPHi"

    assert pubkey.encoded_xpub ==
             "xpub661MyMwAqRbcFtXgS5sYJABqqG9YLmC4Q1Rdap9gSE8NqtwybGhePY2gZ29ESFjqJoCu1Rupje8YtGqsefD265TMg7usUDFdp6W1EGMcet8"
  end

  test "Chain m/0H" do
    seed = @seed |> Base.decode16!(case: :lower)

    master_xprv = BIP32.Xprv.new_master(seed)

    derived = BIP32.Xprv.derive(master_xprv, "m/0H")

    assert "xprv9uHRZZhk6KAJC1avXpDAp4MDc3sQKNxDiPvvkX8Br5ngLNv1TxvUxt4cV1rGL5hj6KCesnDYUhd7oWgT11eZG7XnxHrnYeSvkzY7d2bhkJ7" =
             derived.encoded_xprv

    assert "xpub68Gmy5EdvgibQVfPdqkBBCHxA5htiqg55crXYuXoQRKfDBFA1WEjWgP6LHhwBZeNK1VTsfTFUHCdrfp1bgwQ9xv5ski8PX9rL2dZXvgGDnw" ==
             derived.xpub.encoded_xpub
  end

  test "Chain m/0H/1" do
    seed = @seed |> Base.decode16!(case: :lower)

    master_xprv = BIP32.Xprv.new_master(seed)

    derived = BIP32.Xprv.derive(master_xprv, "m/0H/1")

    assert "xprv9wTYmMFdV23N2TdNG573QoEsfRrWKQgWeibmLntzniatZvR9BmLnvSxqu53Kw1UmYPxLgboyZQaXwTCg8MSY3H2EU4pWcQDnRnrVA1xe8fs" =
             derived.encoded_xprv

    assert "xpub6ASuArnXKPbfEwhqN6e3mwBcDTgzisQN1wXN9BJcM47sSikHjJf3UFHKkNAWbWMiGj7Wf5uMash7SyYq527Hqck2AxYysAA7xmALppuCkwQ" ==
             derived.xpub.encoded_xpub
  end

  test "Chain m/0H/1/2H" do
    seed = @seed |> Base.decode16!(case: :lower)

    master_xprv = BIP32.Xprv.new_master(seed)

    derived = BIP32.Xprv.derive(master_xprv, "m/0H/1/2H")

    assert "xprv9z4pot5VBttmtdRTWfWQmoH1taj2axGVzFqSb8C9xaxKymcFzXBDptWmT7FwuEzG3ryjH4ktypQSAewRiNMjANTtpgP4mLTj34bhnZX7UiM" =
             derived.encoded_xprv

    assert "xpub6D4BDPcP2GT577Vvch3R8wDkScZWzQzMMUm3PWbmWvVJrZwQY4VUNgqFJPMM3No2dFDFGTsxxpG5uJh7n7epu4trkrX7x7DogT5Uv6fcLW5" ==
             derived.xpub.encoded_xpub
  end

  test "Chain m/0H/1/2H/2/1000000000" do
    seed = @seed |> Base.decode16!(case: :lower)

    master_xprv = BIP32.Xprv.new_master(seed)

    derived = BIP32.Xprv.derive(master_xprv, "m/0H/1/2H/2/1000000000")

    assert "xprvA41z7zogVVwxVSgdKUHDy1SKmdb533PjDz7J6N6mV6uS3ze1ai8FHa8kmHScGpWmj4WggLyQjgPie1rFSruoUihUZREPSL39UNdE3BBDu76" =
             derived.encoded_xprv

    assert "xpub6H1LXWLaKsWFhvm6RVpEL9P4KfRZSW7abD2ttkWP3SSQvnyA8FSVqNTEcYFgJS2UaFcxupHiYkro49S8yGasTvXEYBVPamhGW6cFJodrTHy" ==
             derived.xpub.encoded_xpub
  end

  test "Different seed test vector 2 m" do
    seed =
      "fffcf9f6f3f0edeae7e4e1dedbd8d5d2cfccc9c6c3c0bdbab7b4b1aeaba8a5a29f9c999693908d8a8784817e7b7875726f6c696663605d5a5754514e4b484542"
      |> Base.decode16!(case: :lower)

    master_xprv = BIP32.Xprv.new_master(seed)

    derived = BIP32.Xprv.derive(master_xprv, "m")

    assert "xprv9s21ZrQH143K31xYSDQpPDxsXRTUcvj2iNHm5NUtrGiGG5e2DtALGdso3pGz6ssrdK4PFmM8NSpSBHNqPqm55Qn3LqFtT2emdEXVYsCzC2U" =
             derived.encoded_xprv

    assert "xpub661MyMwAqRbcFW31YEwpkMuc5THy2PSt5bDMsktWQcFF8syAmRUapSCGu8ED9W6oDMSgv6Zz8idoc4a6mr8BDzTJY47LJhkJ8UB7WEGuduB" ==
             derived.xpub.encoded_xpub
  end

  test "These vectors test for the retention of leading zeros -> m" do
    seed =
      "4b381541583be4423346c643850da4b320e46a87ae3d2a4e6da11eba819cd4acba45d239319ac14f863b8d5ab5a0d0c64d2e8a1e7d1457df2e5a3c51c73235be"
      |> Base.decode16!(case: :lower)

    master_xprv = BIP32.Xprv.new_master(seed)

    derived = BIP32.Xprv.derive(master_xprv, "m")

    assert "xprv9s21ZrQH143K25QhxbucbDDuQ4naNntJRi4KUfWT7xo4EKsHt2QJDu7KXp1A3u7Bi1j8ph3EGsZ9Xvz9dGuVrtHHs7pXeTzjuxBrCmmhgC6" =
             derived.encoded_xprv

    assert "xpub661MyMwAqRbcEZVB4dScxMAdx6d4nFc9nvyvH3v4gJL378CSRZiYmhRoP7mBy6gSPSCYk6SzXPTf3ND1cZAceL7SfJ1Z3GC8vBgp2epUt13" ==
             derived.xpub.encoded_xpub
  end

  test "These vectors test for the retention of leading zeros -> m/0H" do
    seed =
      "4b381541583be4423346c643850da4b320e46a87ae3d2a4e6da11eba819cd4acba45d239319ac14f863b8d5ab5a0d0c64d2e8a1e7d1457df2e5a3c51c73235be"
      |> Base.decode16!(case: :lower)

    master_xprv = BIP32.Xprv.new_master(seed)

    derived = BIP32.Xprv.derive(master_xprv, "m/0H")

    assert "xprv9uPDJpEQgRQfDcW7BkF7eTya6RPxXeJCqCJGHuCJ4GiRVLzkTXBAJMu2qaMWPrS7AANYqdq6vcBcBUdJCVVFceUvJFjaPdGZ2y9WACViL4L" =
             derived.encoded_xprv

    assert "xpub68NZiKmJWnxxS6aaHmn81bvJeTESw724CRDs6HbuccFQN9Ku14VQrADWgqbhhTHBaohPX4CjNLf9fq9MYo6oDaPPLPxSb7gwQN3ih19Zm4Y" ==
             derived.xpub.encoded_xpub
  end
end
