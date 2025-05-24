defmodule BIP32.Xpub.Test do
  use ExUnit.Case

  @seed "000102030405060708090a0b0c0d0e0f"

  test "correct creation of master key" do
    seed = @seed |> Base.decode16!(case: :lower)

    %{master_pubkey: pubkey} =
      BIP32.Xpriv.new_master(seed)

    assert pubkey.public_key ==
             "xpub661MyMwAqRbcFtXgS5sYJABqqG9YLmC4Q1Rdap9gSE8NqtwybGhePY2gZ29ESFjqJoCu1Rupje8YtGqsefD265TMg7usUDFdp6W1EGMcet8"
  end
end
