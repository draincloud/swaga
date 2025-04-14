require Logger

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

  def parse(s) when is_binary(s) do
    {length, rest} = Tx.read_varint(s)
    cmds = []
    count = 0
    {rest_bin, parsed_cmds} = iter_script(rest, cmds, count, length)
    {rest_bin, %Script{cmds: parsed_cmds}}
  end

  def parse(s) do
    raise "Type error s is not binary"
  end

  def iter_script(<<current_byte, rest::binary>> = s, cmds, count, length)
      when count < length and current_byte >= 1 and current_byte <= 75 do
    <<cmd::binary-size(current_byte), rest_cmds::binary>> = rest
    iter_script(rest_cmds, cmds ++ [cmd], count + 1 + current_byte, length)
  end

  def iter_script(<<76, rest::binary>> = s, cmds, count, length)
      when count < length do
    <<first, rest2::binary>> = rest
    data_length = MathUtils.little_endian_to_int(<<first>>)
    <<cmd::binary-size(data_length), rest3::binary>> = rest2
    iter_script(rest3, cmds ++ [cmd], count + data_length + 2, length)
  end

  def iter_script(<<77, rest::binary>> = s, cmds, count, length)
      when count < length do
    count = count + 1
    <<first_two::binary-size(2), rest2::binary>> = rest
    data_length = MathUtils.little_endian_to_int(first_two)
    <<cmd::binary-size(data_length), rest3::binary>> = rest2
    iter_script(rest3, cmds ++ [cmd], count + data_length + 3, length)
  end

  def iter_script(<<op_code, rest::binary>> = s, cmds, count, length)
      when count < length and is_list(cmds) do
    iter_script(rest, cmds ++ [op_code], count + 1, length)
  end

  def iter_script(s, cmds, count, length) when count >= length do
    if count != length do
      raise "Script parsing failed: mismatched length (expected #{length}, got #{count})"
    end

    {s, cmds}
  end

  def iter_script(_s, cmds, _count, _length) when not is_list(cmds) do
    raise "Cmds must be a list, received #{inspect(cmds)}"
  end

  def raw_serialize(%{cmds: cmds}) do
    # Enum.each(["some", "example"], fn x -> IO.puts(x) end)
    Enum.reduce(cmds, <<>>, fn cmd, acc -> parse_cmd(cmd, acc) end)
  end

  def parse_cmd(cmd, acc) when is_integer(cmd) do
    acc <> MathUtils.int_to_little_endian(cmd, 1)
  end

  def parse_cmd(cmd, acc) when byte_size(cmd) < 75 do
    acc <> MathUtils.int_to_little_endian(byte_size(cmd), 1) <> cmd
  end

  def parse_cmd(cmd, acc) when byte_size(cmd) > 75 and byte_size(cmd) < 0x100 do
    acc <>
      MathUtils.int_to_little_endian(76, 1) <>
      MathUtils.int_to_little_endian(byte_size(cmd), 1) <> cmd
  end

  def parse_cmd(cmd, acc) when byte_size(cmd) >= 0x100 and byte_size(cmd) <= 520 do
    acc <>
      MathUtils.int_to_little_endian(77, 1) <>
      MathUtils.int_to_little_endian(byte_size(cmd), 2) <>
      cmd
  end

  def parse_cmd(_, _) do
    raise "Too long an cmd"
  end

  def serialize(%Script{cmds: cmds} = script) do
    result = raw_serialize(script)
    total = result |> :binary.bin_to_list() |> length
    # todo test this
    Tx.encode_varint(total) <> result
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
