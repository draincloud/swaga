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

  @tag :important
  test "script evaluation" do
    z = 0x7c076ff316692a3d7eb3c3bb0f8b1488cf72e1afcd929e29307032997a838a3d
    sec = Base.decode16!("04887387e452b8eacc4acfde10d9aaf7f6d9a0f975aabb10d006e4da568744d06c61de6d95231cd89026e286df3b6ae4a894a3378e393e93a0f45b666329a0ae34", case: :lower)
    sig = Base.decode16!("3045022000eff69ef2b1bd93a66ed5219add4fb51e11a840f404876325a1e8ffe0529a2c022100c7207fee197d27c618aea621406f6bf5ef6fca38681d82b2f06fddbdce6feab601")
    script_pubkey = Script.new([sec, 0xac])
    script_sig = Script.new([sig])
    combined_script = Script.add(script_pubkey, script_sig)
    Script.evaluate(combined_script)
  end
end
