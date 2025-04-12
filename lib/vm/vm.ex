import Bitwise

defmodule VM do
  def encode_num(num) do
    abs_num = abs(num)
    negative = num < 0
    result = []
    result = encode_num_result(abs_num, result)
    last_byte = List.last(result)

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
    result = result ++ (abs_num &&& 0xFF)
    abs_num = abs_num >>> 8
    encode_num_result(abs_num, result)
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

  def decode_num(element) when is_binary(element) do
    big_endian = element |> :binary.bin_to_list(element) |> Enum.reverse()
    last = List.last(big_endian)
    negative = false
    result = 0

    result =
      if (last &&& 0x80) != 0 do
        negative = true
        last &&& 0x7F
      else
        last
      end

    rest = tl(result)

    result =
      for c <- rest do
        result = result <<< 8
        result = result + c
      end

    final = if negative, do: -result, else: result
    final
  end

  def op_0(stack) do
    stack = stack <> encode_num(0)
    stack
  end

  @op_codenames %{
    0 => 'OP_0'
    #    76 => 'OP_PUSHDATA1',
    #    77 => 'OP_PUSHDATA2'
  }

  @dispatch_table %{
    0 => &__MODULE__.op_0/1
  }

  #    79 => &Vop_1negate,
  #    81 => op_1
  #    78=> 'OP_PUSHDATA4',
  # 79=> 'OP_1NEGATE',
  # 81=> 'OP_1',
  #  82=> 'OP_2',
  #           83=> 'OP_3',
  # 84=> 'OP_4',
  # 85=> 'OP_5',
  #     86=> 'OP_6',
  # 87=> 'OP_7',
  # 88=> 'OP_8',
  #    89=> 'OP_9',
  # 90=> 'OP_10',
  # 91=> 'OP_11',
  #  92=> 'OP_12',
  #            93=> 'OP_13',
  #  94=> 'OP_14',
  #  95=> 'OP_15',
  #       96=> 'OP_16',
  #  97=> 'OP_NOP',
  #  99=> 'OP_IF',
  #      100=> 'OP_NOTIF',
  #  103=> 'OP_ELSE',
  #  104=> 'OP_ENDIF',
  #     105=> 'OP_VERIFY',
  #                    106=> 'OP_RETURN',
  #  107=> 'OP_TOALTSTACK',
  #  108=> 'OP_FROMALTSTACK',
  #        109=> 'OP_2DROP',
  #        110=> 'OP_2DUP',
  #        111=> 'OP_3DUP',
  #             112=> 'OP_2OVER',
  #        113=> 'OP_2ROT',
  #        114=> 'OP_2SWAP',
  #           115=> 'OP_IFDUP',
  #                         116=> 'OP_DEPTH',
  #        117=> 'OP_DROP',
  #        118=> 'OP_DUP',
  #              119=> 'OP_NIP',
  #        120=> 'OP_OVER',
  #        121=> 'OP_PICK',
  #             122=> 'OP_ROLL',
  #                           123=> 'OP_ROT',
  #                           124=> 'OP_SWAP',
  #                              125=> 'OP_TUCK',
  #                                           130=> 'OP_SIZE',
  #                           135=> 'OP_EQUAL',
  #                           136=> 'OP_EQUALVERIFY',
  #                                 139=> 'OP_1ADD',
  #                           140=> 'OP_1SUB',
  #                           143=> 'OP_NEGATE',
  #                                144=> 'OP_ABS',
  #                           145=> 'OP_NOT',
  #                           146=> 'OP_0NOTEQUAL',
  #                              147=> 'OP_ADD',
  #                                          148=> 'OP_SUB',
  # 149=> 'OP_MUL',
  # 154=> 'OP_BOOLAND',
  #      155=> 'OP_BOOLOR',
  # 156=> 'OP_NUMEQUAL',
  # 157=> 'OP_NUMEQUALVERIFY',
  #     158=> 'OP_NUMNOTEQUAL',
  # 159=> 'OP_LESSTHAN',
  # 160=> 'OP_GREATERTHAN',
  #   161=> 'OP_LESSTHANOREQUAL',
  #                           162=> 'OP_GREATERTHANOREQUAL',
  # 163=> 'OP_MIN',
  # 164=> 'OP_MAX',
  #      165=> 'OP_WITHIN',
  # 166=> 'OP_RIPEMD160',
  # 167=> 'OP_SHA1',
  #     168=> 'OP_SHA256',
  #     169=> 'OP_HASH160',
  #     170=> 'OP_HASH256',
  #        171=> 'OP_CODESEPARATOR',
  #                              172=> 'OP_CHECKSIG',
  #     173=> 'OP_CHECKSIGVERIFY',
  #     174=> 'OP_CHECKMULTISIG',
  #           175=> 'OP_CHECKMULTISIGVERIFY',
  #     176=> 'OP_NOP1',
  #     177=> 'OP_CHECKLOCKTIMEVERIFY',
  #          178=> 'OP_CHECKSEQUENCEVERIFY',
  #     179=> 'OP_NOP4',
  #     180=> 'OP_NOP5',
  #        181=> 'OP_NOP6',
  #                     182=> 'OP_NOP7',
  #                     183=> 'OP_NOP8',
  #                     184=> 'OP_NOP9',
  #                           185=> 'OP_NOP10',
  #                     }
  #
  # 82=> op_2,
  # 83=> op_3,
  # 84=> op_4,
  # 85=> op_5,
  # 86=> op_6,
  # 87=> op_7,
  # 88=> op_8,
  # 89=> op_9,
  # 90=> op_10,
  # 91=> op_11,
  # 92=> op_12,
  # 93=> op_13,
  # 94=> op_14,
  # 95=> op_15,
  # 96=> op_16,
  # 97=> op_nop,
  # 99=> op_if,
  # 100=> op_notif,
  # 105=> op_verify,
  # 106=> op_return,
  # 107=> op_toaltstack,
  # 108=> op_fromaltstack,
  # 109=> op_2drop,
  # 110=> op_2dup,
  # 111=> op_3dup,
  # 112=> op_2over,
  # 113=> op_2rot,
  # 114=> op_2swap,
  # 115=> op_ifdup,
  # 116=> op_depth,
  # 117=> op_drop,
  # 118=> op_dup,
  # 119=> op_nip,
  # 120=> op_over,
  # 121=> op_pick,
  # 122=> op_roll,
  # 123=> op_rot,
  # 124=> op_swap,
  # 125=> op_tuck,
  # 130=> op_size,
  # 135=> op_equal,
  # 136=> op_equalverify,
  # 139=> op_1add,
  # 140=> op_1sub,
  # 143=> op_negate,
  # 144=> op_abs,
  # 145=> op_not,
  # 146=> op_0notequal,
  # 147=> op_add,
  # 148=> op_sub,
  # 149=> op_mul,
  # 154=> op_booland,
  # 155=> op_boolor,
  # 156=> op_numequal,
  # 157=> op_numequalverify,
  # 158=> op_numnotequal,
  # 159=> op_lessthan,
  # 160=> op_greaterthan,
  # 161=> op_lessthanorequal,
  # 162=> op_greaterthanorequal,
  # 163=> op_min,
  # 164=> op_max,
  # 165=> op_within,
  # 166=> op_ripemd160,
  # 167=> op_sha1,
  # 168=> op_sha256,
  # 169=> op_hash160,
  # 170=> op_hash256,
  # 172=> op_checksig,
  # 173=> op_checksigverify,
  # 174=> op_checkmultisig,
  # 175=> op_checkmultisigverify,
  # 176=> op_nop,
  # 177=> op_checklocktimeverify,
  # 178=> op_checksequenceverify,
  # 179=> op_nop,
  # 180=> op_nop,
  # 181=> op_nop,
  # 182=> op_nop,
  # 183=> op_nop,
  # 184=> op_nop,
  # 185 => op_nop
  #  }
  #
  #  def run do
  #
  #  end
end
