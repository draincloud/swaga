defmodule SignaturePointTest do
  use ExUnit.Case

  test "sqrt 123" do
    fe = Secp256Field.new(10)
    fe_sqrt = Secp256Field.sqrt fe
    assert fe_sqrt == %FieldElement{
      num: 1, # ??
      prime: 115792089237316195423570985008687907853269984665640564039457584007908834671663,
    }
  end
end
