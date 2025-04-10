defmodule Script do
  @enforce_keys [
    :cmds
  ]
  defstruct [
    :cmds
  ]

  #  @op_dup 0x76
  #  @op_hash256 170
  #  @op_hash160 0xA9
  #  @op_0 0x00
  #  @op_1 0x51
  #  @op16 0x60
  #  @op_add 0x93
  #  @op_checksig 0xAC

  def add(%{cmds: cmds}, %{cmds: cmds_other}) when is_list(cmds) and is_list(cmds_other) do
    %Script{cmds: cmds ++ cmds_other}
  end

  def new(cmds) when is_list(cmds) do
    %Script{cmds: cmds}
  end

  def new do
    %Script{cmds: []}
  end

  def op_dup(stack) when is_list(stack) and length(stack) < 1 do
    false
  end

  def op_dup(stack) when is_list(stack) do
    stack = stack ++ Enum.take(stack, -1)
    {true, stack}
  end

  def op_hash256(stack) when is_list(stack) and length(stack) < 1 do
    false
  end

  def op_hash256(stack) when is_list(stack) do
    {elem, _} = List.pop_at(stack, -1)
    stack = stack ++ CryptoUtils.hash_256(elem)
    {true, stack}
  end

  def op_hash160(stack) when is_list(stack) and length(stack) < 1 do
    false
  end

  def op_hash160(stack) when is_list(stack) do
    {elem, _} = List.pop_at(stack, -1)
    stack = stack ++ CryptoUtils.hash160(elem)
    {true, stack}
  end

  def parse(s) do
    length = Tx.read_varint(s)
    cmds = []
    count = 0
    cmds = iter_script(s, cmds, count, length)
    cmds
  end

  def iter_script(<<current_byte, rest::binary>> = s, cmds, count, length)
      when count < length and current_byte >= 1 and current_byte <= 75 do
    count = count + 1
    <<cmd::binary-size(current_byte), _::binary>> = rest
    cmds = cmds ++ cmd
    count = count + current_byte
    iter_script(s, cmds, count, length)
  end

  def iter_script(<<current_byte, _::binary>> = s, cmds, count, length)
      when count < length and current_byte == 76 do
    count = count + 1
    <<first, rest::binary>> = s
    data_length = MathUtils.little_endian_to_int(first)
    <<cmd::binary-size(data_length), _::binary>> = rest
    cmds = cmds ++ cmd
    count = count + data_length + 1
    {s, cmds} = iter_script(s, cmds, count, length)
  end

  def iter_script(<<current_byte, _::binary>> = s, cmds, count, length)
      when count < length and current_byte == 77 do
    count = count + 1
    <<first_two::binary-size(2), rest::binary>> = s
    data_length = MathUtils.little_endian_to_int(first_two)
    <<cmd::binary-size(data_length), _>> = rest
    cmds = cmds ++ cmd
    count = count + data_length + 2
    iter_script(s, cmds, count, length)
  end

  def iter_script(<<op_code, _::binary>> = s, cmds, count, length) when count < length do
    count = count + 1
    cmds = cmds ++ op_code
    iter_script(s, cmds, count, length)
  end

  def iter_script(s, cmds, count, length) when count >= length do
    {s, cmds}
  end

  def raw_serialize(%{cmds: cmds}) do
    result = 0
    # Enum.each(["some", "example"], fn x -> IO.puts(x) end)
    Enum.reduce(cmds, result, fn cmd -> parse_cmd(cmd, result) end)
  end

  def parse_cmd(cmd, result) when is_integer(cmd) do
    result = result + MathUtils.int_to_little_endian(cmd, 1)
    result + cmd
  end

  def parse_cmd(cmd, result) when length(cmd) < 75 do
    result = result + MathUtils.int_to_little_endian(length(cmd), 1)
    result + cmd
  end

  def parse_cmd(cmd, result) when length(cmd) > 75 and length(cmd) < 0x100 do
    result = result + MathUtils.int_to_little_endian(76, 1)
    result = result + MathUtils.int_to_little_endian(length(cmd), 1)
    result + cmd
  end

  def parse_cmd(cmd, result) when length(cmd) >= 0x100 and length(cmd) <= 520 do
    result = result + MathUtils.int_to_little_endian(77, 1)
    result = result + MathUtils.int_to_little_endian(length(cmd), 2)
    result + cmd
  end

  def parse_cmd(_, _) do
    raise "Too long an cmd"
  end

  def serialize(%Script{cmds: _cmds}) do
#    result = raw_serialize(cmds)
#    total = length(result)
#    # todo test this
#    Tx.encode_varint(total) + result
  end

  def evaluate(%Script{cmds: cmds}, _z) do
    _cmds_copy = cmds
    _stack = []
    _alt_stack = []
  end

  #  def iter_over_script_commands([cmd | rest]) when is_int(cmd) do
  #    operation =
  #  end
end
