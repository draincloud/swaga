require Logger

defmodule ScriptTest do
  use ExUnit.Case

  test "correctly parses script" do
    script_pubkey =
      Base.decode16!(
        "6a47304402207899531a52d59a6de200179928ca900254a36b8dff8bb75f5f5d71b1cdc26125022008b422690b8461cb52c3cc30330b23d574351872b7c361e9aae3649071c1a7160121035d5c93d9ac96881f19ba1f686f15f009ded7c62efe85a872e6a19b43c15a2937",
        case: :mixed
      )

    {_, %{cmds: cmds}} = Script.parse(script_pubkey)

    want =
      Base.decode16!(
        "304402207899531a52d59a6de200179928ca900254a36b8dff8bb75f5f5d71b1cdc26125022008b422690b8461cb52c3cc30330b23d574351872b7c361e9aae3649071c1a71601",
        case: :mixed
      )

    [first_cmd | rest_cmds] = cmds
    assert Base.encode16(first_cmd) == Base.encode16(want)

    want =
      Base.decode16!("035d5c93d9ac96881f19ba1f686f15f009ded7c62efe85a872e6a19b43c15a2937",
        case: :mixed
      )

    [want_cmd | _] = rest_cmds
    assert want_cmd == want
  end

  test "correctly serialize script" do
    want =
      "6a47304402207899531a52d59a6de200179928ca900254a36b8dff8bb75f5f5d71b1cdc26125022008b422690b8461cb52c3cc30330b23d574351872b7c361e9aae3649071c1a7160121035d5c93d9ac96881f19ba1f686f15f009ded7c62efe85a872e6a19b43c15a2937"

    script_pubkey = Base.decode16!(want, case: :mixed)
    {_, script} = Script.parse(script_pubkey)
    assert Base.encode16(Script.serialize(script), case: :lower) == want
  end

  test "script evaluation" do
    z = 0x7C076FF316692A3D7EB3C3BB0F8B1488CF72E1AFCD929E29307032997A838A3D

    sec =
      Base.decode16!(
        "04887387e452b8eacc4acfde10d9aaf7f6d9a0f975aabb10d006e4da568744d06c61de6d95231cd89026e286df3b6ae4a894a3378e393e93a0f45b666329a0ae34",
        case: :mixed
      )

    sig =
      Base.decode16!(
        "3045022000eff69ef2b1bd93a66ed5219add4fb51e11a840f404876325a1e8ffe0529a2c022100c7207fee197d27c618aea621406f6bf5ef6fca38681d82b2f06fddbdce6feab601",
        case: :mixed
      )

    script_pubkey = Script.new([sec, 0xAC])
    script_sig = Script.new([sig])
    combined_script = Script.add(script_pubkey, script_sig)
    Script.evaluate(combined_script)
  end

  #  * `56 = OP_6`
  #  * `76 = OP_DUP`
  #  * `87 = OP_EQUAL`
  #  * `93 = OP_ADD`
  #  * `95 = OP_MUL`
  test "ScriptSig that can unlock that ScriptPubkey" do
    script_pubkey = Script.new([0x76, 0x76, 0x95, 0x93, 0x56, 0x87])
    script_sig = Script.new([0x52])
    combined_script = Script.add(script_sig, script_pubkey)
    {:ok} = Script.evaluate(combined_script, 0)
  end

  #  * `69 = OP_VERIFY`
  #  * `6e = OP_2DUP`
  #  * `7c = OP_SWAP`
  #  * `87 = OP_EQUAL`
  #  * `91 = OP_NOT`
  #  * `a7 = OP_SHA1`
  test "Script.parse and evaluate op_codes" do
    script_pubkey = Script.new([0x6E, 0x87, 0x91, 0x69, 0xA7, 0x7C, 0xA7, 0x87])

    c1 =
      "255044462d312e330a25e2e3cfd30a0a0a312030206f626a0a3c3c2f57696474682032203020522f4865696768742033203020522f547970652034203020522f537562747970652035203020522f46696c7465722036203020522f436f6c6f7253706163652037203020522f4c656e6774682038203020522f42697473506572436f6d706f6e656e7420383e3e0a73747265616d0affd8fffe00245348412d3120697320646561642121212121852fec092339759c39b1a1c63c4c97e1fffe017f46dc93a6b67e013b029aaa1db2560b45ca67d688c7f84b8c4c791fe02b3df614f86db1690901c56b45c1530afedfb76038e972722fe7ad728f0e4904e046c230570fe9d41398abe12ef5bc942be33542a4802d98b5d70f2a332ec37fac3514e74ddc0f2cc1a874cd0c78305a21566461309789606bd0bf3f98cda8044629a1"

    c2 =
      "255044462d312e330a25e2e3cfd30a0a0a312030206f626a0a3c3c2f57696474682032203020522f4865696768742033203020522f547970652034203020522f537562747970652035203020522f46696c7465722036203020522f436f6c6f7253706163652037203020522f4c656e6774682038203020522f42697473506572436f6d706f6e656e7420383e3e0a73747265616d0affd8fffe00245348412d3120697320646561642121212121852fec092339759c39b1a1c63c4c97e1fffe017346dc9166b67e118f029ab621b2560ff9ca67cca8c7f85ba84c79030c2b3de218f86db3a90901d5df45c14f26fedfb3dc38e96ac22fe7bd728f0e45bce046d23c570feb141398bb552ef5a0a82be331fea48037b8b5d71f0e332edf93ac3500eb4ddc0decc1a864790c782c76215660dd309791d06bd0af3f98cda4bc4629b1"

    collision1 = Base.decode16!(c1, case: :mixed)
    collision2 = Base.decode16!(c2, case: :mixed)
    script_sig = Script.new([collision1, collision2])
    combined_script = Script.add(script_sig, script_pubkey)
    {:ok} = Script.evaluate(combined_script, 0)
  end
end
