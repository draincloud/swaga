require Logger
import Bitwise

defmodule VM do
  #  def execute(stack, opcode) do
  #    func = fetch_operation(opcode)
  #    func.(stack)
  #  end

  def fetch_operation(cmd) when is_integer(cmd) do
    Map.fetch!(opcode_functions(), cmd)
  end

  def encode_num(0) do
    <<>>
  end

  def encode_num(num) do
    abs_num = abs(num)
    negative = num < 0
    result = []
    result = encode_num_result(abs_num, result)
    last_byte = List.last(result)
    Logger.debug("result #{inspect(result)}")
    Logger.debug("num #{inspect(num)}")

    result =
      cond do
        (last_byte &&& 0x80) != 0 ->
          result ++ [if(negative, do: 0x80, else: 0)]

        negative ->
          last_byte = last_byte ||| 0x80
          List.replace_at(result, -1, last_byte)

        true ->
          result
      end

    :erlang.list_to_binary(result)
  end

  defp encode_num_result(abs_num, result) when abs_num > 0 do
    upd_result = [result ++ (abs_num &&& 0xFF)]
    upd_abs_num = abs_num >>> 8
    encode_num_result(upd_abs_num, upd_result)
  end

  defp encode_num_result(abs_num, result) when abs_num == 0 do
    result
  end

  defp encode_check_result_last_element(result, is_negative) when is_negative do
    result = result ++ 0x80
  end

  defp encode_check_result_last_element(result, is_negative) when not is_negative do
    result = result ++ 0
  end

  def decode_num(<<>>), do: 0

  def decode_num(element) when is_binary(element) do
    Logger.debug("element #{inspect(element)}")
    big_endian = element |> :binary.bin_to_list() |> Enum.reverse()
    Logger.debug("big_endian #{inspect(big_endian)}")
    last = List.last(big_endian)
    negative = false
    result = 0

    Logger.debug("last #{inspect(last)}")

    result =
      if (last &&& 0x80) != 0 do
        negative = true
        last &&& 0x7F
      else
        last
      end

    # returns tail of the list, except the first elem
    rest = tl(big_endian)

    result = decode_num_result_c(result, rest)

    final = if negative, do: -result, else: result
    final
  end

  defp decode_num_result_c(result, [c | rest]) do
    result = result <<< 8
    result = result + c
    decode_num_result_c(result, rest)
  end

  defp decode_num_result_c(result, []) do
    result
  end

  # ---------------OPs------------------------
  def op_0(stack), do: {:ok, stack ++ [encode_num(0)]}
  def op_1(stack), do: {:ok, stack ++ [encode_num(1)]}
  def op_1negate(stack), do: {:ok, stack ++ [encode_num(-1)]}
  def op_2(stack), do: {:ok, stack ++ [encode_num(2)]}
  def op_3(stack), do: {:ok, stack ++ [encode_num(3)]}
  def op_4(stack), do: {:ok, stack ++ [encode_num(4)]}
  def op_5(stack), do: {:ok, stack ++ [encode_num(5)]}
  def op_6(stack), do: {:ok, stack ++ [encode_num(6)]}
  def op_7(stack), do: {:ok, stack ++ [encode_num(7)]}
  def op_8(stack), do: {:ok, stack ++ [encode_num(8)]}
  def op_9(stack), do: {:ok, stack ++ [encode_num(9)]}
  def op_10(stack), do: {:ok, stack ++ [encode_num(10)]}
  def op_11(stack), do: {:ok, stack ++ [encode_num(11)]}
  def op_12(stack), do: {:ok, stack ++ [encode_num(12)]}
  def op_13(stack), do: {:ok, stack ++ [encode_num(13)]}
  def op_14(stack), do: {:ok, stack ++ [encode_num(14)]}
  def op_15(stack), do: {:ok, stack ++ [encode_num(15)]}
  def op_16(stack), do: {:ok, stack ++ [encode_num(16)]}
  def op_nop(stack), do: {:ok, stack}

  def op_if(stack, items) do
    true_items = []
    false_items = []
    current_array = []
    found = false
    num_endifs_needed = 1

    {item, true_items, false_items, current_array, found, num_endifs_needed} =
      iterate_over_stack(items, true_items, false_items, current_array, found, num_endifs_needed)

    if not found do
      {:error, stack}
    end

    [element | rest_stack] = stack

    items =
      if decode_num(element) == 0 do
        false_items ++ items
      else
        true_items ++ items
      end

    {:ok, stack}
  end

  def op_if(stack, items) when length(stack) < 1 do
    {:error, stack}
  end

  defp match_last_stack_item_op_if(
         item,
         true_items,
         false_items,
         current_array,
         found,
         num_endifs_needed
       ) do
    cond do
      item in [99, 100] ->
        num_endifs_needed = num_endifs_needed + 1
        current_array = [item | current_array]

      num_endifs_needed == 1 and item == 103 ->
        current_array = false_items

      item == 104 and num_endifs_needed == 1 ->
        found = true
        {item, true_items, false_items, current_array, found, num_endifs_needed}

      item == 104 ->
        num_endifs_needed = num_endifs_needed - 1
        current_array = [item | current_array]

      true ->
        current_array = [item | current_array]
    end

    {item, true_items, false_items, current_array, found, num_endifs_needed}
  end

  defp iterate_over_stack(
         [],
         true_items,
         false_items,
         current_array,
         found,
         num_endifs_needed
       ) do
    {nil, true_items, false_items, current_array, found, num_endifs_needed}
  end

  defp iterate_over_stack(items, true_items, false_items, current_array, found, num_endifs_needed) do
    # pattern match list and list with length = 1
    {init, [last]} = Enum.split(items, length(items) - 1)

    {item, true_items, false_items, current_array, found, num_endifs_needed} =
      match_last_stack_item_op_if(
        last,
        true_items,
        false_items,
        current_array,
        found,
        num_endifs_needed
      )

    iterate_over_stack(init, true_items, false_items, current_array, found, num_endifs_needed)
  end

  def op_dup(stack) when length(stack) < 1 do
    {:error, stack}
  end

  def op_dup(stack) when is_list(stack) do
    {:ok, stack ++ Enum.take(stack, -1)}
  end

  def op_hash256(stack) when is_list(stack) and length(stack) < 1 do
    {:error, stack}
  end

  def op_hash256(stack) when is_list(stack) do
    {elem, _} = List.pop_at(stack, -1)
    stack = stack ++ CryptoUtils.hash_256(elem)
    {:ok, stack}
  end

  def op_hash160(stack) when is_list(stack) and length(stack) < 1 do
    {:error, stack}
  end

  def op_hash160(stack) when is_list(stack) do
    {elem, _} = List.pop_at(stack, -1)
    stack = stack ++ CryptoUtils.hash160(elem)
    {:ok, stack}
  end

  # length must be >= 2
  def op_equal(stack) when length(stack) >= 2 do
    [elem1, elem2 | rest] = Enum.reverse(stack)

    if elem1 == elem2 do
      {:ok, stack ++ [encode_num(1)]}
    else
      {:ok, stack ++ [encode_num(0)]}
    end
  end

  # length must be >= 2
  def op_add(stack) when length(stack) >= 2 do
    [elem1, elem2 | rest] = Enum.reverse(stack)
    decoded_elem1 = decode_num(elem1)
    decoded_elem2 = decode_num(elem2)
    {:ok, rest ++ [encode_num(decoded_elem1 + decoded_elem2)]}
  end

  # length must be >= 2
  def op_mul(stack) when length(stack) >= 2 do
    [elem1, elem2 | rest] = Enum.reverse(stack)
    decoded_elem1 = decode_num(elem1)
    decoded_elem2 = decode_num(elem2)
    {:ok, rest ++ [encode_num(decoded_elem1 * decoded_elem2)]}
  end

  def op_verify(stack) when length(stack) >= 1 do
    [elem | rest] = Enum.reverse(stack)

    if decode_num(elem) == 0 do
      {:error, rest}
    else
      {:ok, rest}
    end
  end

  # Append two elements
  def op_2dup(stack) when length(stack) >= 2 do
    [elem1, elem2 | _] = Enum.reverse(stack)
    {:ok, stack ++ [elem2, elem1]}
  end

  def op_swap(stack) when length(stack) >= 2 do
    [elem1, elem2 | rest] = Enum.reverse(stack)
    {:ok, rest ++ [elem1, elem2]}
  end

  def op_not(stack) when length(stack) >= 1 do
    [elem | rest] = Enum.reverse(stack)

    stack =
      if decode_num(elem) == 0 do
        rest ++ [encode_num(1)]
      else
        rest ++ [encode_num(0)]
      end

    {:ok, stack}
  end

  def op_sha1(stack) when length(stack) >= 1 do
    [elem | rest] = Enum.reverse(stack)
    {:ok, rest ++ [CryptoUtils.sha1(elem)]}
  end

  opcode_names = %{
    0 => "OP_0",
    76 => "OP_PUSHDATA1",
    77 => "OP_PUSHDATA2",
    78 => "OP_PUSHDATA4",
    79 => "OP_1NEGATE",
    81 => "OP_1",
    82 => "OP_2",
    83 => "OP_3",
    84 => "OP_4",
    85 => "OP_5",
    86 => "OP_6",
    87 => "OP_7",
    88 => "OP_8",
    89 => "OP_9",
    90 => "OP_10",
    91 => "OP_11",
    92 => "OP_12",
    93 => "OP_13",
    94 => "OP_14",
    95 => "OP_15",
    96 => "OP_16",
    97 => "OP_NOP",
    99 => "OP_IF",
    100 => "OP_NOTIF",
    103 => "OP_ELSE",
    104 => "OP_ENDIF",
    105 => "OP_VERIFY",
    106 => "OP_RETURN",
    107 => "OP_TOALTSTACK",
    108 => "OP_FROMALTSTACK",
    109 => "OP_2DROP",
    110 => "OP_2DUP",
    111 => "OP_3DUP",
    112 => "OP_2OVER",
    113 => "OP_2ROT",
    114 => "OP_2SWAP",
    115 => "OP_IFDUP",
    116 => "OP_DEPTH",
    117 => "OP_DROP",
    118 => "OP_DUP",
    119 => "OP_NIP",
    120 => "OP_OVER",
    121 => "OP_PICK",
    122 => "OP_ROLL",
    123 => "OP_ROT",
    124 => "OP_SWAP",
    125 => "OP_TUCK",
    130 => "OP_SIZE",
    135 => "OP_EQUAL",
    136 => "OP_EQUALVERIFY",
    139 => "OP_1ADD",
    140 => "OP_1SUB",
    143 => "OP_NEGATE",
    144 => "OP_ABS",
    145 => "OP_NOT",
    146 => "OP_0NOTEQUAL",
    147 => "OP_ADD",
    148 => "OP_SUB",
    149 => "OP_MUL",
    154 => "OP_BOOLAND",
    155 => "OP_BOOLOR",
    156 => "OP_NUMEQUAL",
    157 => "OP_NUMEQUALVERIFY",
    158 => "OP_NUMNOTEQUAL",
    159 => "OP_LESSTHAN",
    160 => "OP_GREATERTHAN",
    161 => "OP_LESSTHANOREQUAL",
    162 => "OP_GREATERTHANOREQUAL",
    163 => "OP_MIN",
    164 => "OP_MAX",
    165 => "OP_WITHIN",
    166 => "OP_RIPEMD160",
    167 => "OP_SHA1",
    168 => "OP_SHA256",
    169 => "OP_HASH160",
    170 => "OP_HASH256",
    171 => "OP_CODESEPARATOR",
    172 => "OP_CHECKSIG",
    173 => "OP_CHECKSIGVERIFY",
    174 => "OP_CHECKMULTISIG",
    175 => "OP_CHECKMULTISIGVERIFY",
    176 => "OP_NOP1",
    177 => "OP_CHECKLOCKTIMEVERIFY",
    178 => "OP_CHECKSEQUENCEVERIFY",
    179 => "OP_NOP4",
    180 => "OP_NOP5",
    181 => "OP_NOP6",
    182 => "OP_NOP7",
    183 => "OP_NOP8",
    184 => "OP_NOP9",
    185 => "OP_NOP10"
  }

  defp opcode_functions(),
    do: %{
      0 => &__MODULE__.op_0/1,
      79 => &__MODULE__.op_1negate/1,
      81 => &__MODULE__.op_1/1,
      82 => &__MODULE__.op_2/1,
      83 => &__MODULE__.op_3/1,
      84 => &__MODULE__.op_4/1,
      85 => &__MODULE__.op_5/1,
      86 => &__MODULE__.op_6/1,
      87 => &__MODULE__.op_7/1,
      88 => &__MODULE__.op_8/1,
      89 => &__MODULE__.op_9/1,
      90 => &__MODULE__.op_10/1,
      91 => &__MODULE__.op_11/1,
      92 => &__MODULE__.op_12/1,
      93 => &__MODULE__.op_13/1,
      94 => &__MODULE__.op_14/1,
      95 => &__MODULE__.op_15/1,
      96 => &__MODULE__.op_16/1,
      97 => &__MODULE__.op_nop/1,
      99 => &__MODULE__.op_if/2,
      100 => &__MODULE__.op_notif/2,
      105 => &__MODULE__.op_verify/1,
      106 => &__MODULE__.op_return/1,
      107 => &__MODULE__.op_toaltstack/2,
      108 => &__MODULE__.op_fromaltstack/2,
      109 => &__MODULE__.op_2drop/1,
      110 => &__MODULE__.op_2dup/1,
      111 => &__MODULE__.op_3dup/1,
      112 => &__MODULE__.op_2over/1,
      113 => &__MODULE__.op_2rot/1,
      114 => &__MODULE__.op_2swap/1,
      115 => &__MODULE__.op_ifdup/1,
      116 => &__MODULE__.op_depth/1,
      117 => &__MODULE__.op_drop/1,
      118 => &__MODULE__.op_dup/1,
      119 => &__MODULE__.op_nip/1,
      120 => &__MODULE__.op_over/1,
      121 => &__MODULE__.op_pick/1,
      122 => &__MODULE__.op_roll/1,
      123 => &__MODULE__.op_rot/1,
      124 => &__MODULE__.op_swap/1,
      125 => &__MODULE__.op_tuck/1,
      130 => &__MODULE__.op_size/1,
      135 => &__MODULE__.op_equal/1,
      136 => &__MODULE__.op_equalverify/1,
      139 => &__MODULE__.op_1add/1,
      140 => &__MODULE__.op_1sub/1,
      143 => &__MODULE__.op_negate/1,
      144 => &__MODULE__.op_abs/1,
      145 => &__MODULE__.op_not/1,
      146 => &__MODULE__.op_0notequal/1,
      147 => &__MODULE__.op_add/1,
      148 => &__MODULE__.op_sub/1,
      149 => &__MODULE__.op_mul/1,
      154 => &__MODULE__.op_booland/1,
      155 => &__MODULE__.op_boolor/1,
      156 => &__MODULE__.op_numequal/1,
      157 => &__MODULE__.op_numequalverify/1,
      158 => &__MODULE__.op_numnotequal/1,
      159 => &__MODULE__.op_lessthan/1,
      160 => &__MODULE__.op_greaterthan/1,
      161 => &__MODULE__.op_lessthanorequal/1,
      162 => &__MODULE__.op_greaterthanorequal/1,
      163 => &__MODULE__.op_min/1,
      164 => &__MODULE__.op_max/1,
      165 => &__MODULE__.op_within/1,
      166 => &__MODULE__.op_ripemd160/1,
      167 => &__MODULE__.op_sha1/1,
      168 => &__MODULE__.op_sha256/1,
      169 => &__MODULE__.op_hash160/1,
      170 => &__MODULE__.op_hash256/1,
      172 => &__MODULE__.op_checksig/2,
      173 => &__MODULE__.op_checksigverify/2,
      174 => &__MODULE__.op_checkmultisig/2,
      175 => &__MODULE__.op_checkmultisigverify/2,
      176 => &__MODULE__.op_nop/1,
      177 => &__MODULE__.op_checklocktimeverify/3,
      178 => &__MODULE__.op_checksequenceverify/3,
      179 => &__MODULE__.op_nop/1,
      180 => &__MODULE__.op_nop/1,
      181 => &__MODULE__.op_nop/1,
      182 => &__MODULE__.op_nop/1,
      183 => &__MODULE__.op_nop/1,
      184 => &__MODULE__.op_nop/1,
      185 => &__MODULE__.op_nop/1
    }
end
