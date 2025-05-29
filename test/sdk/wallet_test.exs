defmodule Sdk.WalletTest do
  use ExUnit.Case

  test "mnemonic generate" do
    mnemonic_list = Sdk.Wallet.generate_mnemonic()
    assert is_list(mnemonic_list) and length(mnemonic_list) == 12
  end
end
