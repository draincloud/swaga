require Logger

defmodule Bip32Test do
  require IEx
  use ExUnit.Case
  @seed "000102030405060708090a0b0c0d0e0f"

  #  https://github.com/bitcoin/bips/blob/master/bip-0032.mediawiki#test-vectors
  test "correct creation of master key" do
    seed = @seed |> Base.decode16!(case: :lower)

    %{chain_code: chain_code, secret: secret, depth: 0, child_number: 0, master_pubkey: pubkey} =
      BIP32.Xpriv.new_master(seed)

    assert secret ==
             "xprv9s21ZrQH143K3QTDL4LXw2F7HEK3wJUD2nW2nRk4stbPy6cq3jPPqjiChkVvvNKmPGJxWUtg6LnF5kejMRNNU3TGtRBeJgk33yuGBxrMPHi"

    assert pubkey.public_key ==
             "xpub661MyMwAqRbcFtXgS5sYJABqqG9YLmC4Q1Rdap9gSE8NqtwybGhePY2gZ29ESFjqJoCu1Rupje8YtGqsefD265TMg7usUDFdp6W1EGMcet8"
  end

  @tag :in_progress
  test "Chain m/0H" do
    seed = @seed |> Base.decode16!(case: :lower)

    master_xprv = BIP32.Xpriv.new_master(seed)

    123 = BIP32.Xpriv.derive(master_xprv, "m/0H")
  end
end
