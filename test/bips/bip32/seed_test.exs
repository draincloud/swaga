defmodule BIP32.Seed.Test do
  use ExUnit.Case

  test "mnemonic test" do
    mnemonic = "dentist save glimpse fossil govern tag gesture beach angle carbon head comic"
    {:ok, seed} = BIP32.Seed.from_mnemonic(mnemonic)

    assert seed ==
             "8831b9adfb820d72c9419dc84fe3214c5511300ed00f971903883e9ff46d4b3e531e41972271af110e2ca542860944dc5f4723d134ac7c4379f17083a70c0909"
  end

  test "mnemonic test + passphrase" do
    mnemonic = "dentist save glimpse fossil govern tag gesture beach angle carbon head comic"
    {:ok, seed} = BIP32.Seed.from_mnemonic(mnemonic, "strong_passphrase")

    assert seed ==
             "17fe9508886057f71062117e1c42cf8eb952c6a0a752339549f7bb39f94eb8647c935705252ec2d80b22e24eb1babe818c55e48b5803721eed16220bcfb87328"
  end
end
