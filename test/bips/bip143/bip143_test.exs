defmodule Tx.Segwit.BIP143Test do
  use ExUnit.Case
  alias Tx.Segwit.BIP143
  alias Tx
  alias TxIn
  alias CryptoUtils

  test "bip143" do
    receiver_address = "mkjykgkDYWePhvofKMkLqq3AEwcTYDZP3s"

    sender_pubkey_hash =
      "03d2ea744829ee2ec2b84e5a384f0316483598f0db27e9c01fc37e0190088be28e"
      |> Base.decode16!(case: :lower)
      |> CryptoUtils.hash160()

    prev_tx =
      "cc05853720254f9f44f151ad25ed5b0391aecae39c4642681b9d3e3a97e62212"
      |> Base.decode16!(case: :lower)

    prev_index = 0
    tx_in = TxIn.new(prev_tx, prev_index, Script.new(), 0xFFFFFFFF, :segwit)

    change_h160 = Base58.decode(receiver_address)
    change_script = Script.p2pkh_script(change_h160)
    change_amount = trunc(8000)
    change_output = TxOut.new(change_amount, change_script)

    target_amount = trunc(1000)
    target_h160 = Base58.decode(receiver_address)
    target_script = Script.p2pkh_script(target_h160)
    target_output = TxOut.new(target_amount, target_script)

    tx = Tx.new(2, [tx_in], [change_output, target_output], 0)

    assert "362dbabf30ae67339d703ae801c389b6af64cfddb113e216b3f325fc2d9018a9" ==
             BIP143.sig_hash_bip143_p2wpkh(tx, 0, sender_pubkey_hash)
             |> Base.encode16(case: :lower)
  end
end
