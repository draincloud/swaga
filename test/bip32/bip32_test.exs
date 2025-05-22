require Logger

defmodule Bip32Test do
  require IEx
  use ExUnit.Case

  #  # XPUB Xpub
  #  # { network: Main, depth: 0, parent_fingerprint: 00000000, child_number: Normal { index: 0 },
  #  # public_key: 0339a36013301597daef41fbe593a02cc513d0b55527ec2df1050e2e8ff49c85c2,
  #  # chain_code: 873dff81c02f525623fd1fe5167eac3a55a049de3d314bb42ee227ffed37d508 }
  #  test "derivation paths" do
  #    expected_sk =
  #      "xprv9s21ZrQH143K3QTDL4LXw2F7HEK3wJUD2nW2nRk4stbPy6cq3jPPqjiChkVvvNKmPGJxWUtg6LnF5kejMRNNU3TGtRBeJgk33yuGBxrMPHi"
  #
  #    expected_pk =
  #      "xpub661MyMwAqRbcFtXgS5sYJABqqG9YLmC4Q1Rdap9gSE8NqtwybGhePY2gZ29ESFjqJoCu1Rupje8YtGqsefD265TMg7usUDFdp6W1EGMcet8"
  #
  #    %{chain_code: chain_code, secret: secret, depth: 0, child_number: 0} =
  #      pk =
  #      Xpriv.new_master(@seed)
  #
  #    pk = Xpub.from_xpriv(pk)
  #    IEx.pry()
  #  end
end
