defmodule BIP32.Xpriv.Test do
  use ExUnit.Case

  @seed "000102030405060708090a0b0c0d0e0f"

  test "correct creation of master key" do
    seed = @seed |> Base.decode16!(case: :lower)

    %{chain_code: chain_code, secret: secret, depth: 0, child_number: 0} =
      BIP32.Xpriv.new_master(seed)

    assert secret ==
             "xprv9s21ZrQH143K3QTDL4LXw2F7HEK3wJUD2nW2nRk4stbPy6cq3jPPqjiChkVvvNKmPGJxWUtg6LnF5kejMRNNU3TGtRBeJgk33yuGBxrMPHi"
  end
end
