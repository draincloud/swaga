defmodule Tx.Segwit.BIP143Test do
  use ExUnit.Case
  alias Tx.Segwit.BIP143
  alias CryptoUtils

  test "bip143" do
    receiver_address = "mthgYuwnJUnjqNVgjSMnoRysj1bkXJwSvq"

    prev_tx =
      "eb98b02392caa172fd1a2e4e91c8a581cd333e3e39fe9a9969afa64ab5c31673"
      |> Base.decode16!(case: :lower)

    prev_index = 1
    tx_in = TxIn.new(prev_tx, prev_index)

    change_h160 = Base58.decode(receiver_address)
    change_script = Script.p2pkh_script(change_h160)
    change_amount = trunc(0.00008 * 100_000_000)
    change_output = TxOut.new(change_amount, change_script)

    target_amount = trunc(0.00001 * 100_000_000)
    target_h160 = Base58.decode(receiver_address)
    target_script = Script.p2pkh_script(target_h160)
    target_output = TxOut.new(target_amount, target_script)

    tx = Tx.new(1, [tx_in], [change_output, target_output], 0, true)
    pubkey_hash = receiver_address |> CryptoUtils.double_hash256(:bin)

    assert "4AE0D40042C356F5F8ED99DA2C4DACD4A629FD0B245A2650EB485DBBCB6AA604" ==
             BIP143.sig_hash_bip143_p2wpkh(tx, 0, pubkey_hash) |> Base.encode16()
  end
end
