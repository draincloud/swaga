require Logger

defmodule EccTest do
  use ExUnit.Case
  doctest Point

  test "should exist on curve" do
    prime = 223
    a = FieldElement.new(0, prime)
    b = FieldElement.new(7, prime)
    x = FieldElement.new(192, prime)
    y = FieldElement.new(105, prime)
    assert %Point{x: x, y: y, a: a, b: b} == Point.new(x, y, a, b)
    x = FieldElement.new(17, prime)
    y = FieldElement.new(56, prime)
    assert %Point{x: x, y: y, a: a, b: b} == Point.new(x, y, a, b)
    x = FieldElement.new(1, prime)
    y = FieldElement.new(193, prime)
    assert %Point{x: x, y: y, a: a, b: b} == Point.new(x, y, a, b)
  end

  test "should not exist on curve and throw an error" do
    prime = 223
    a = FieldElement.new(0, prime)
    b = FieldElement.new(7, prime)
    x = FieldElement.new(200, prime)
    y = FieldElement.new(119, prime)

    assert_raise ArgumentError, "Cannot create a point, y3 != x3", fn ->
      Point.new(x, y, a, b)
    end

    x = FieldElement.new(42, prime)
    y = FieldElement.new(99, prime)

    assert_raise ArgumentError, "Cannot create a point, y3 != x3", fn ->
      Point.new(x, y, a, b)
    end
  end

  test "Coding Point Addition over Finite Fields" do
    prime = 223
    a = FieldElement.new(0, prime)
    b = FieldElement.new(7, prime)
    x1 = FieldElement.new(192, prime)
    y1 = FieldElement.new(105, prime)
    x2 = FieldElement.new(17, prime)
    y2 = FieldElement.new(56, prime)
    p1 = Point.new(x1, y1, a, b)
    p2 = Point.new(x2, y2, a, b)
    # assert
    x3 = FieldElement.new(170, prime)
    y3 = FieldElement.new(142, prime)
    assert %Point{x: x3, y: y3, a: a, b: b} == Point.add(p1, p2)
  end

  test "y^2 = x^3 + 7 over F223 for (170,142) + (60,139)" do
    prime = 223
    a = FieldElement.new(0, prime)
    b = FieldElement.new(7, prime)
    x1 = FieldElement.new(170, prime)
    y1 = FieldElement.new(142, prime)
    x2 = FieldElement.new(60, prime)
    y2 = FieldElement.new(139, prime)
    p1 = Point.new(x1, y1, a, b)
    p2 = Point.new(x2, y2, a, b)
    # assert
    x3 = FieldElement.new(220, prime)
    y3 = FieldElement.new(181, prime)
    assert %Point{x: x3, y: y3, a: a, b: b} == Point.add(p1, p2)
  end

  test "y^2 = x^3 + 7 over F223 for (47,71) + (17,56)" do
    prime = 223
    a = FieldElement.new(0, prime)
    b = FieldElement.new(7, prime)
    x1 = FieldElement.new(47, prime)
    y1 = FieldElement.new(71, prime)
    x2 = FieldElement.new(17, prime)
    y2 = FieldElement.new(56, prime)
    p1 = Point.new(x1, y1, a, b)
    p2 = Point.new(x2, y2, a, b)
    # assert
    x3 = FieldElement.new(215, prime)
    y3 = FieldElement.new(68, prime)
    assert %Point{x: x3, y: y3, a: a, b: b} == Point.add(p1, p2)
  end

  test "y^2 = x^3 + 7 over F223 for (143,98) + (76,66)" do
    prime = 223
    a = FieldElement.new(0, prime)
    b = FieldElement.new(7, prime)
    x1 = FieldElement.new(143, prime)
    y1 = FieldElement.new(98, prime)
    x2 = FieldElement.new(76, prime)
    y2 = FieldElement.new(66, prime)
    p1 = Point.new(x1, y1, a, b)
    p2 = Point.new(x2, y2, a, b)
    # assert
    x3 = FieldElement.new(47, prime)
    y3 = FieldElement.new(71, prime)
    assert %Point{x: x3, y: y3, a: a, b: b} == Point.add(p1, p2)
  end

  test "multiply points (2, 192, 105, 49, 71)" do
    prime = 223
    a = FieldElement.new(0, prime)
    b = FieldElement.new(7, prime)

    x1 = FieldElement.new(192, prime)
    y1 = FieldElement.new(105, prime)
    x2 = FieldElement.new(49, prime)
    y2 = FieldElement.new(71, prime)
    p1 = Point.new(x1, y1, a, b)
    p2 = Point.new(x2, y2, a, b)
    assert Point.mul(p1, 2) == p2
  end

  test "multiply points (2, 143, 98, 64, 168)" do
    prime = 223
    a = FieldElement.new(0, prime)
    b = FieldElement.new(7, prime)

    x1 = FieldElement.new(143, prime)
    y1 = FieldElement.new(98, prime)
    x2 = FieldElement.new(64, prime)
    y2 = FieldElement.new(168, prime)
    p1 = Point.new(x1, y1, a, b)
    p2 = Point.new(x2, y2, a, b)
    assert Point.mul(p1, 2) == p2
  end

  test "multiply points (2, 47, 71, 36, 111)" do
    prime = 223
    a = FieldElement.new(0, prime)
    b = FieldElement.new(7, prime)

    x1 = FieldElement.new(47, prime)
    y1 = FieldElement.new(71, prime)
    x2 = FieldElement.new(36, prime)
    y2 = FieldElement.new(111, prime)
    p1 = Point.new(x1, y1, a, b)
    p2 = Point.new(x2, y2, a, b)
    assert Point.mul(p1, 2) == p2
  end

  test "multiply points (4, 47, 71, 194, 51)" do
    prime = 223
    a = FieldElement.new(0, prime)
    b = FieldElement.new(7, prime)

    x1 = FieldElement.new(47, prime)
    y1 = FieldElement.new(71, prime)
    x2 = FieldElement.new(194, prime)
    y2 = FieldElement.new(51, prime)
    p1 = Point.new(x1, y1, a, b)
    p2 = Point.new(x2, y2, a, b)
    assert Point.mul(p1, 4) == p2
  end

  test "multiply points (8, 47, 71, 116, 55)" do
    prime = 223
    a = FieldElement.new(0, prime)
    b = FieldElement.new(7, prime)

    x1 = FieldElement.new(47, prime)
    y1 = FieldElement.new(71, prime)
    x2 = FieldElement.new(116, prime)
    y2 = FieldElement.new(55, prime)
    p1 = Point.new(x1, y1, a, b)
    p2 = Point.new(x2, y2, a, b)
    assert Point.mul(p1, 8) == p2
  end

  test "multiply points (21, 47, 71, None, None)" do
    prime = 223
    a = FieldElement.new(0, prime)
    b = FieldElement.new(7, prime)

    x1 = FieldElement.new(47, prime)
    y1 = FieldElement.new(71, prime)
    x2 = FieldElement.new(nil, prime)
    y2 = FieldElement.new(nil, prime)
    p1 = Point.new(x1, y1, a, b)
    p2 = Point.new(x2, y2, a, b)
    assert Point.mul(p1, 21) == p2
  end

  #  @tag :important
  test "verify signature using primitives" do
    z = 0xBC62D4B80D9E36DA29C16C5D4D9F11731F36052C72401A76C23C0FB5A9B74423
    r = 0x37206A0610995C58074999CB9767B87AF4C4978DB68C06E8E6E81D282047A7C6
    s = 0x8CA63759C1157EBEAEC0D03CECCA119FC9A75BF8E6D0FA65C841C8E2738CDAEC
    px = 0x04519FAC3D910CA7E7138F7013706F619FA8F033E6EC6E09370EA38CEE6A7574
    py = 0x82B51EAB8C27C66E26C858A079BCDF4F1ADA34CEC420CAFC7EAC1A42216FB6C4
    point = Secp256Point.new(px, py)
    n = Secp256Point.n()
    # Note that we use Fermat’s little theorem for 1/s, since n is prime.
    s_inv = MathUtils.powmod(s, n - 2, n)
    # u = z/s
    u = rem(z * s_inv, n)
    # v = r/s
    v = rem(r * s_inv, n)
    g = Secp256Point.get_g()
    # uG + vP = (r,y). We need to check that the x coordinate is r.
    res = Point.add(Secp256Point.mul(g, u), Secp256Point.mul(point, v))
    assert res.x.num == r
  end
end
