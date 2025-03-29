require Logger

defmodule SignatureTest do
  use ExUnit.Case
  doctest Signature

  test "secret message signature" do
    e = 12345
    z = MathUtils.hash_to_int(~c"Programming Bitcoin!")
    k = 1_234_567_890
    g = Secp256Point.get_g()
    n = Secp256Point.n()
    k_inv = MathUtils.powmod(k, n - 2, n)
    r = Secp256Point.mul(g, k).x.num
    s = rem((z + r * e) * k_inv, n)
    point = Secp256Point.mul(g, e)

    assert point.x.num ==
             108_607_064_596_551_879_580_190_606_910_245_687_803_607_295_064_141_551_927_605_737_287_325_610_911_759

    assert point.y.num ==
             6_661_302_038_839_728_943_522_144_359_728_938_428_925_407_345_457_796_456_954_441_906_546_235_843_221

    assert s ==
             13_449_928_304_528_854_552_621_297_743_528_922_715_969_746_175_462_178_470_032_064_141_974_217_735_194

    assert Integer.to_string(z, 16) ==
             "969F6056AA26F7D2795FD013FE88868D09C9F6AED96965016E1936AE47060D48"

    assert Integer.to_string(r, 16) ==
             "2B698A0F0A4041B77E63488AD48C23E8E8838DD1FB7520408B121697B782EF22"
  end

  test "der format" do
    r = 0x37206A0610995C58074999CB9767B87AF4C4978DB68C06E8E6E81D282047A7C6
    s = 0x8CA63759C1157EBEAEC0D03CECCA119FC9A75BF8E6D0FA65C841C8E2738CDAEC
    sig = Signature.new(r, s)

    assert Base.encode16(Signature.der(sig)) ==
             "3045022037206A0610995C58074999CB9767B87AF4C4978DB68C06E8E6E81D282047A7C60221008CA63759C1157EBEAEC0D03CECCA119FC9A75BF8E6D0FA65C841C8E2738CDAEC"
  end
end
