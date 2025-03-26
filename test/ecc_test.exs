import CustomOperators

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

#  test "multiply points" do
#    prime = 223
#    s = 2
#    a = FieldElement.new(0, prime)
#    b = FieldElement.new(7, prime)
#
#    x1_raw = FieldElement.new(192, prime)
#    y1_raw = FieldElement.new(105, prime)
#    x2_raw = FieldElement.new(49, prime)
#    y2_raw = FieldElement.new(71, prime)
#    p1 = Point.new(x1_raw, y1_raw, a, b)
#    p2 = Point.new(x2_raw, y2_raw, a, b)
#    assert Point.mul(p1, s) == p2
#  end
end
