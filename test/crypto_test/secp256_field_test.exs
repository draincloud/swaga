defmodule Secp256FieldTest do
  use ExUnit.Case

  test "sqrt 123" do
    fe = Secp256Field.new(10)
    fe_sqrt = Secp256Field.sqrt(fe)

    assert fe_sqrt == %FieldElement{
             num:
               31_011_223_725_017_966_638_128_227_314_025_066_779_206_457_760_849_946_047_862_801_023_559_985_823_831,
             prime:
               115_792_089_237_316_195_423_570_985_008_687_907_853_269_984_665_640_564_039_457_584_007_908_834_671_663
           }
  end
end
