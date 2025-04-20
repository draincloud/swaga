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
end
