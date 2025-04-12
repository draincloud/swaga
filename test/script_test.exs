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
end
