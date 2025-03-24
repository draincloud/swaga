defmodule PointTest do
  use ExUnit.Case
  doctest Point

  test "creates infinity" do
    assert Point.new(nil, nil, 5, 7) ==
             %Point{x: nil, y: nil, a: 5, b: 7}
  end
  test "creates correctly" do
    assert Point.new(-1, -1, 5, 7) ==
             %Point{x: -1, y: -1, a: 5, b: 7}
  end

  test "should throw an error" do
    assert_raise ArgumentError, "Cannot create a point", fn ->
      Point.new(-1, -2, 5, 7)
    end
  end

    test "should be equal" do
      p1 = Point.new(-1, -1, 5, 7)
      p2 = Point.new(-1, -1, 5, 7)
      assert Point.equals?(p1, p2) == true
    end

    test "should not be equal" do
      p1 = Point.new(-1, -1, 5, 7)
      p2 = Point.new(18, 77, 5, 7)
      assert Point.equals?(p1, p2) == false
    end
end
