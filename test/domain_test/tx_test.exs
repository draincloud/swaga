require Logger

defmodule TxTest do
  use ExUnit.Case
  #  @moduletag :skip

  test "parse version" do
    raw_tx =
      Base.decode16!(
        "0100000001813f79011acb80925dfe69b3def355fe914bd1d96a3f5f71bf8303c6a989c7d1000000006b483045022100ed81ff192e75a3fd2304004dcadb746fa5e24c5031ccfcf21320b0277457c98f02207a986d955c6e0cb35d446a89d3f56100f4d7f67801c31967743a9c8e10615bed01210349fc4e631e3624a545de3f89f5d8684c7b8138bd94bdd531d2e213bf016b278afeffffff02a135ef01000000001976a914bc3b654dca7e56b04dca18f2566cdaf02e8d9ada88ac99c39800000000001976a9141c4bc762dd5423e332166702cb75f40df79fea1288ac19430600",
        case: :mixed
      )

    assert Tx.parse(raw_tx).version == 1
  end

  test "parse inputs" do
    raw_tx =
      Base.decode16!(
        "0100000001813f79011acb80925dfe69b3def355fe914bd1d96a3f5f71bf8303c6a989c7d1000000006b483045022100ed81ff192e75a3fd2304004dcadb746fa5e24c5031ccfcf21320b0277457c98f02207a986d955c6e0cb35d446a89d3f56100f4d7f67801c31967743a9c8e10615bed01210349fc4e631e3624a545de3f89f5d8684c7b8138bd94bdd531d2e213bf016b278afeffffff02a135ef01000000001976a914bc3b654dca7e56b04dca18f2566cdaf02e8d9ada88ac99c39800000000001976a9141c4bc762dd5423e332166702cb75f40df79fea1288ac19430600",
        case: :mixed
      )

    %Tx{version: ver, tx_ins: inputs} = Tx.parse(raw_tx)
    assert ver == 1
    assert length(inputs) == 1

    {:ok, want} =
      Base.decode16("d1c789a9c60383bf715f3f6ad9d14b91fe55f3deb369fe5d9280cb1a01793f81",
        case: :mixed
      )

    [first_input | _] = inputs
    assert first_input.prev_tx == want

    {:ok, want} =
      Base.decode16(
        "6b483045022100ed81ff192e75a3fd2304004dcadb746fa5e24c5031ccfcf21320b0277457c98f02207a986d955c6e0cb35d446a89d3f56100f4d7f67801c31967743a9c8e10615bed01210349fc4e631e3624a545de3f89f5d8684c7b8138bd94bdd531d2e213bf016b278a",
        case: :mixed
      )

    assert Script.serialize(first_input.script_sig) == want
    assert first_input.sequence == 0xFFFFFFFE
  end

  test "parse outputs" do
    raw_tx =
      Base.decode16!(
        "0100000001813f79011acb80925dfe69b3def355fe914bd1d96a3f5f71bf8303c6a989c7d1000000006b483045022100ed81ff192e75a3fd2304004dcadb746fa5e24c5031ccfcf21320b0277457c98f02207a986d955c6e0cb35d446a89d3f56100f4d7f67801c31967743a9c8e10615bed01210349fc4e631e3624a545de3f89f5d8684c7b8138bd94bdd531d2e213bf016b278afeffffff02a135ef01000000001976a914bc3b654dca7e56b04dca18f2566cdaf02e8d9ada88ac99c39800000000001976a9141c4bc762dd5423e332166702cb75f40df79fea1288ac19430600",
        case: :mixed
      )

    %Tx{tx_outs: outputs} = Tx.parse(raw_tx)
    assert length(outputs) == 2
    [first_output | rest_outputs] = outputs
    want = 32_454_049
    assert first_output.amount == want
    want = Base.decode16!("1976a914bc3b654dca7e56b04dca18f2566cdaf02e8d9ada88ac", case: :mixed)
    assert Script.serialize(first_output.script_pubkey) == want
    [second_output | _] = rest_outputs
    want = 10_011_545
    assert second_output.amount == want
    want = Base.decode16!("1976a914bc3b654dca7e56b04dca18f2566cdaf02e8d9ada88ac", case: :mixed)
    assert Script.serialize(first_output.script_pubkey) == want
  end

  test "parse locktime" do
    raw_tx =
      Base.decode16!(
        "0100000001813f79011acb80925dfe69b3def355fe914bd1d96a3f5f71bf8303c6a989c7d1000000006b483045022100ed81ff192e75a3fd2304004dcadb746fa5e24c5031ccfcf21320b0277457c98f02207a986d955c6e0cb35d446a89d3f56100f4d7f67801c31967743a9c8e10615bed01210349fc4e631e3624a545de3f89f5d8684c7b8138bd94bdd531d2e213bf016b278afeffffff02a135ef01000000001976a914bc3b654dca7e56b04dca18f2566cdaf02e8d9ada88ac99c39800000000001976a9141c4bc762dd5423e332166702cb75f40df79fea1288ac19430600",
        case: :mixed
      )

    %Tx{locktime: locktime} = Tx.parse(raw_tx)
    assert locktime == 410_393
  end

  test "sig_hash" do
    tx = TxFetcher.fetch("452c629d67e41baec3ac6f04fe744b4b9617f8f859c63b3002f8684e7a4fee03")

    want =
      String.to_integer("27e0c5994dec7824e56dec6b2fcb342eb7cdb0d0957c2fce9882f715e85d81a6", 16)

    assert Tx.sig_hash(tx, 0) == want
  end

  test "converting the modified transaction to z" do
    modified_tx =
      Base.decode16!(
        "0100000001813f79011acb80925dfe69b3def355fe914bd1d96a3f5f71bf8303c6a989c7d1000000001976a914a802fc56c704ce87c42d7c92eb75e7896bdc41ae88acfeffffff02a135ef01000000001976a914bc3b654dca7e56b04dca18f2566cdaf02e8d9ada88ac99c39800000000001976a9141c4bc762dd5423e332166702cb75f40df79fea1288ac1943060001000000",
        case: :lower
      )

    h256 = CryptoUtils.double_hash256(modified_tx)

    assert Integer.to_string(h256, 16) |> String.downcase() ==
             "27e0c5994dec7824e56dec6b2fcb342eb7cdb0d0957c2fce9882f715e85d81a6"
  end

  test "tx creation" do
    prev_tx =
      Base.decode16!("0d6fe5213c0b3291f208cba8bfb59b7476dffacc4e5cb66f6eb20a080843a299",
        case: :lower
      )

    prev_index = 13
    tx_in = TxIn.new(prev_tx, prev_index)
    change_amount = trunc(0.33 * 100_000_000)
    change_h160 = Base58.decode("mzx5YhAH9kNHtcN481u6WkjeHjYtVeKVh2")
    change_script = Script.p2pkh_script(change_h160)
    change_output = TxOut.new(change_amount, change_script)
    target_amount = trunc(0.1 * 100_000_000)
    target_h160 = Base58.decode("mnrVtF8DWjMu839VW3rBfgYaAfKk8983Xf")
    target_script = Script.p2pkh_script(target_h160)
    target_output = TxOut.new(target_amount, target_script)
    tx = Tx.new(1, [tx_in], [change_output, target_output], 0, true)
    id = Tx.id(tx)
    assert id == "cd30a8da777d28ef0e61efe68a9f7c559c1d3e5bcd7b265c850ccb4068598d11"
  end

  test "test tx serialize" do
    raw_tx =
      Base.decode16!(
        "0100000001813f79011acb80925dfe69b3def355fe914bd1d96a3f5f71bf8303c6a989c7d1000000006b483045022100ed81ff192e75a3fd2304004dcadb746fa5e24c5031ccfcf21320b0277457c98f02207a986d955c6e0cb35d446a89d3f56100f4d7f67801c31967743a9c8e10615bed01210349fc4e631e3624a545de3f89f5d8684c7b8138bd94bdd531d2e213bf016b278afeffffff02a135ef01000000001976a914bc3b654dca7e56b04dca18f2566cdaf02e8d9ada88ac99c39800000000001976a9141c4bc762dd5423e332166702cb75f40df79fea1288ac19430600",
        case: :mixed
      )

    tx = Tx.parse(raw_tx)
    assert Tx.is_coinbase(tx) == false
    assert Tx.serialize(tx) == raw_tx
  end

  test "is_coinbase" do
    raw_tx =
      Base.decode16!(
        "01000000010000000000000000000000000000000000000000000000000000000000000000ffffffff5e03d71b07254d696e656420627920416e74506f6f6c20626a31312f4542312f4144362f43205914293101fabe6d6d678e2c8c34afc36896e7d9402824ed38e856676ee94bfdb0c6c4bcd8b2e5666a0400000000000000c7270000a5e00e00ffffffff01faf20b58000000001976a914338c84849423992471bffb1a54a8d9b1d69dc28a88ac00000000",
        case: :lower
      )

    tx = Tx.parse(raw_tx)
    assert Tx.is_coinbase(tx)
  end

  test "coinbase height" do
    raw_tx =
      Base.decode16!(
        "01000000010000000000000000000000000000000000000000000000000000000000000000ffffffff5e03d71b07254d696e656420627920416e74506f6f6c20626a31312f4542312f4144362f43205914293101fabe6d6d678e2c8c34afc36896e7d9402824ed38e856676ee94bfdb0c6c4bcd8b2e5666a0400000000000000c7270000a5e00e00ffffffff01faf20b58000000001976a914338c84849423992471bffb1a54a8d9b1d69dc28a88ac00000000",
        case: :lower
      )

    tx = Tx.parse(raw_tx)
    assert Tx.is_coinbase(tx)
    assert 465_879 == Tx.coinbase_height(tx)
  end

  test "nil coinbase height" do
    raw_tx =
      Base.decode16!(
        "0100000001813f79011acb80925dfe69b3def355fe914bd1d96a3f5f71bf8303c6a989c7d1000000006b483045022100ed81ff192e75a3fd2304004dcadb746fa5e24c5031ccfcf21320b0277457c98f02207a986d955c6e0cb35d446a89d3f56100f4d7f67801c31967743a9c8e10615bed01210349fc4e631e3624a545de3f89f5d8684c7b8138bd94bdd531d2e213bf016b278afeffffff02a135ef01000000001976a914bc3b654dca7e56b04dca18f2566cdaf02e8d9ada88ac99c39800000000001976a9141c4bc762dd5423e332166702cb75f40df79fea1288ac19430600",
        case: :lower
      )

    tx = Tx.parse(raw_tx)
    assert false == Tx.is_coinbase(tx)
    assert nil == Tx.coinbase_height(tx)
  end
end
