require Logger

defmodule ScriptVMTest do
  use ExUnit.Case

  # This test cannot be tested properly yet
  @tag :not_ready
  test "OP_IF inserts true_items if top stack element is non-zero" do
    # Stack top = 1, should trigger true_items path
    stack = [VM.encode_num(1)]
    # 99=OP_IF, 103=OP_ELSE, 104=OP_ENDIF
    items = [99, :A, 103, :B, 104]
    # Pattern match the result with true
    {:ok, _res} = VM._op_if(stack, items)
  end

  test "op hash160" do
    stack = ["hello world"]
    {:ok, updated_stack} = VM.op_hash160(stack)

    want = "d7d5ee7824ff93f94c3055af9382c86c68b5ca92"
    assert want == Base.encode16(Enum.at(updated_stack, 0), case: :lower)
  end

  @tag :in_progress
  test "op checkmultisig" do
    z = 0xE71BFA115715D6FD33796948126F40A8CDD39F187E4AFB03896795189FE1423C

    sig1 =
      Base.decode16!(
        "3045022100dc92655fe37036f47756db8102e0d7d5e28b3beb83a8fef4f5dc0559bddfb94e02205a36d4e4e6c7fcd16658c50783e00c341609977aed3ad00937bf4ee942a8993701",
        case: :mixed
      )

    sig2 =
      Base.decode16!(
        "3045022100da6bee3c93766232079a01639d07fa869598749729ae323eab8eef53577d611b02207bef15429dcadce2121ea07f233115c6f09034c0be68db99980b9a6c5e75402201",
        case: :mixed
      )

    sec1 =
      Base.decode16!("022626e955ea6ea6d98850c994f9107b036b1334f18ca8830bfff1295d21cfdb70",
        case: :mixed
      )

    sec2 =
      Base.decode16!("03b287eaf122eea69030a0e9feed096bed8045c8b98bec453e1ffac7fbdbd4bb71",
        case: :mixed
      )

    stack = [<<>>, sig1, sig2, <<0x02>>, sec1, sec2, <<0x02>>]
    {:ok, _bin} = VM.op_checkmultisig(stack, z)
  end
end
