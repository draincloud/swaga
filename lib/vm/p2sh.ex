defmodule VM.Script.P2SH do
  def execute(cmd, cmds, stack) do
    with true <- length(cmds) >= 3,
         # Execute the next three opcodes
         # We're checking that the next three commands conform to the BIP0016
         [_, h160, _ | cmds] = Enum.reverse(cmds),
         {:ok, updated_stack} <- VM.op_hash160(stack),
         new_stack = updated_stack ++ [h160],
         {:ok, updated_stack} <- VM.op_equal(new_stack),
         {:ok, updated_stack} <- VM.op_verify(updated_stack),
         redeem_script = Transaction.encode_varint(length(cmd)) <> cmd,
         {_, script} <- Script.parse(redeem_script) do
      {cmds ++
         script.cmds, updated_stack}
    else
      {:error, reason} -> {:error, reason}
    end
  end
end
