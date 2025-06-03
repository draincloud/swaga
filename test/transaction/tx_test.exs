defmodule TxTest do
  alias Tx
  require Logger
  use ExUnit.Case

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
    Logger.error(Tx.serialize(tx) |> Base.encode16(case: :lower))
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

  test "parse SEGWIT testnet transaction id: eb98b02392caa172fd1a2e4e91c8a581cd333e3e39fe9a9969afa64ab5c31673" do
    tx_body =
      "0200000000010144fe8feb6464f806f12d39e7acbb43564d7af87d72dea78fef80eed30e407b310100000000fdffffff02feb9af0000000000160014a34874fcb2e92e33014383b842456b486fb3acfb102700000000000016001449a548c3bc6fd00c1e6f9d9c0080f10219f7342202473044022000b67441ebbbaab8172499e792d28bb8e535e6afa0f70764c1060e57f5c75525022045b86c1c98a75948960215cd5221c0db8871f8d2dce58b5999de8ade15d15403012102857892c09c438ebfa4d13cecb5fd2fb3956a32f173ce4e8a22c92126cd2e2e90b6694400"

    tx = Tx.parse(tx_body, true)
    assert 2 == tx.version
    assert 2 == tx.tx_outs |> length
    assert 11_516_414 == Enum.at(tx.tx_outs, 0).amount
    assert 10000 == Enum.at(tx.tx_outs, 1).amount
    assert 4_483_510 == tx.locktime
  end
end
