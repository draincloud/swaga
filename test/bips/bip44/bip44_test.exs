defmodule BIP44.Test do
  use ExUnit.Case
  @seed "000102030405060708090a0b0c0d0e0f"

  test "correct creation of master key" do
    seed = @seed |> Base.decode16!(case: :lower)

    master_xprv =
      BIP32.Xprv.new_master(seed)

    derived = BIP32.Xprv.derive(master_xprv, "m/44'/0'/0'/0")

    assert "xprvA2EqnHNMfq9w1nDwQanUKHtfZcn4xvGAbc2ugxHMbnDdQbQUm9w6EWF7ZKmXG4NhQyFF7vp6AtoAFjxtc56osAtRKA1T9KJYwfiesFD8wiT" =
             derived.encoded_xprv

    assert "xpub6FECBnuFWCiEEGJQWcKUgRqQ7ecZNNz1xpxWVLgyA7kcHPjdJhFLnJZbQbvQSPVr2R9xVWXjoVgGUom21dw9AkQkiKKz2YYGYGUdj7RaiNA" ==
             derived.xpub.encoded_xpub
  end
end
