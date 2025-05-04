require Logger

defmodule TxTest do
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

  test "fee" do
    raw_tx =
      Base.decode16!(
        "0100000001813f79011acb80925dfe69b3def355fe914bd1d96a3f5f71bf8303c6a989c7d1000000006b483045022100ed81ff192e75a3fd2304004dcadb746fa5e24c5031ccfcf21320b0277457c98f02207a986d955c6e0cb35d446a89d3f56100f4d7f67801c31967743a9c8e10615bed01210349fc4e631e3624a545de3f89f5d8684c7b8138bd94bdd531d2e213bf016b278afeffffff02a135ef01000000001976a914bc3b654dca7e56b04dca18f2566cdaf02e8d9ada88ac99c39800000000001976a9141c4bc762dd5423e332166702cb75f40df79fea1288ac19430600",
        case: :mixed
      )

    transaction = Tx.parse(raw_tx)
    assert Tx.fee(transaction, false) == 40000

    raw_tx =
      Base.decode16!(
        "010000000456919960ac691763688d3d3bcea9ad6ecaf875df5339e148a1fc61c6ed7a069e010000006a47304402204585bcdef85e6b1c6af5c2669d4830ff86e42dd205c0e089bc2a821657e951c002201024a10366077f87d6bce1f7100ad8cfa8a064b39d4e8fe4ea13a7b71aa8180f012102f0da57e85eec2934a82a585ea337ce2f4998b50ae699dd79f5880e253dafafb7feffffffeb8f51f4038dc17e6313cf831d4f02281c2a468bde0fafd37f1bf882729e7fd3000000006a47304402207899531a52d59a6de200179928ca900254a36b8dff8bb75f5f5d71b1cdc26125022008b422690b8461cb52c3cc30330b23d574351872b7c361e9aae3649071c1a7160121035d5c93d9ac96881f19ba1f686f15f009ded7c62efe85a872e6a19b43c15a2937feffffff567bf40595119d1bb8a3037c356efd56170b64cbcc160fb028fa10704b45d775000000006a47304402204c7c7818424c7f7911da6cddc59655a70af1cb5eaf17c69dadbfc74ffa0b662f02207599e08bc8023693ad4e9527dc42c34210f7a7d1d1ddfc8492b654a11e7620a0012102158b46fbdff65d0172b7989aec8850aa0dae49abfb84c81ae6e5b251a58ace5cfeffffffd63a5e6c16e620f86f375925b21cabaf736c779f88fd04dcad51d26690f7f345010000006a47304402200633ea0d3314bea0d95b3cd8dadb2ef79ea8331ffe1e61f762c0f6daea0fabde022029f23b3e9c30f080446150b23852028751635dcee2be669c2a1686a4b5edf304012103ffd6f4a67e94aba353a00882e563ff2722eb4cff0ad6006e86ee20dfe7520d55feffffff0251430f00000000001976a914ab0c0b2e98b1ab6dbf67d4750b0a56244948a87988ac005a6202000000001976a9143c82d7df364eb6c75be8c80df2b3eda8db57397088ac46430600",
        case: :mixed
      )

    transaction = Tx.parse(raw_tx)
    assert Tx.fee(transaction, false) == 140_500
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

  test "verify p2pkh" do
    tx = TxFetcher.fetch("452c629d67e41baec3ac6f04fe744b4b9617f8f859c63b3002f8684e7a4fee03")
    assert true == Tx.verify(tx)
  end

  test "verify_p2sh" do
    tx = TxFetcher.fetch("46df1a9484d0a81d03ce0ee543ab6e1a23ed06175c104a178268fad381216c2b")
    assert true == Tx.verify(tx)
  end

  test "tx creation" do
    prev_tx =
      Base.decode16!("0d6fe5213c0b3291f208cba8bfb59b7476dffacc4e5cb66f6eb20a080843a299",
        case: :lower
      )

    prev_index = 13
    tx_in = TxIn.new(prev_tx, prev_index, nil, nil)
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

  test "sign input" do
    private_key = PrivateKey.new(8_675_309)

    tx_raw =
      Base.decode16!(
        "010000000199a24308080ab26e6fb65c4eccfadf76749bb5bfa8cb08f291320b3c21e56f0d0d00000000ffffffff02408af701000000001976a914d52ad7ca9b3d096a38e752c2018e6fbc40cdf26f88ac80969800000000001976a914507b27411ccf7f16f10297de6cef3f291623eddf88ac00000000",
        case: :mixed
      )

    tx_obj = Tx.parse(tx_raw, true)
    {{:ok}, updated_tx} = Tx.sign_input(tx_obj, 0, private_key)

    want =
      "010000000199a24308080ab26e6fb65c4eccfadf76749bb5bfa8cb08f291320b3c21e56f0d0d0000006b4830450221008dff35729f06444748c9a0ebc9e42224d42adcdc3c60f7a7a80d7064378f2d3002202b1ce60e8a5c81407dbb76aa559903693cad709195a8767796331afce2d44683012103935581e52c354cd2f484fe8ed83af7a3097005b2f9c60bff71d35bd795f54b67ffffffff02408af701000000001976a914d52ad7ca9b3d096a38e752c2018e6fbc40cdf26f88ac80969800000000001976a914507b27411ccf7f16f10297de6cef3f291623eddf88ac00000000"

    assert want == Base.encode16(Tx.serialize(updated_tx), case: :lower)
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
