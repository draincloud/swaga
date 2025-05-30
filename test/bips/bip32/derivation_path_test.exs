defmodule BIP32.DerivationPath.Test do
  use ExUnit.Case

  test "check parse" do
    parsed = BIP32.DerivationPath.parse("m/0'")
    [0x80000000] = parsed
    parsed = BIP32.DerivationPath.parse("m/0H/1/2H/2/1000000000")
    [0x80000000, 1, 2_147_483_650, 2, 1_000_000_000] = parsed
  end
end
