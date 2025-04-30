defmodule Secp256FieldTest do
  use ExUnit.Case

  test "sqrt 123" do
    fe = Secp256Field.new(10)
    fe_sqrt = Secp256Field.sqrt(fe)

    assert fe_sqrt == %FieldElement{
             num: 1,
             prime:
               115_792_089_237_316_195_423_570_985_008_687_907_853_269_984_665_640_564_039_457_584_007_908_834_671_663
           }
  end
end
