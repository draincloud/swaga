defmodule FieldElementTest do
  use ExUnit.Case
  doctest FieldElement

  test "pow negative correctly" do
    f1 = FieldElement.new(17, 31)
    f2 = FieldElement.new(29, 31)
    assert FieldElement.pow(f1, -3) == f2
  end

  test "pow positive correctly" do
    f1 = FieldElement.new(7, 19)
    f2 = FieldElement.new(1, 19)
    assert FieldElement.pow(f1, 3) == f2
  end

  test "div positive" do
    f1 = FieldElement.new(2, 19)
    f2 = FieldElement.new(7, 19)
    assert FieldElement.div(f1, f2) == FieldElement.new(3, 19)
  end

  test "on_curve" do
    x = FieldElement.new(192, 223)
    y = FieldElement.new(105, 223)
    assert FieldElement.on_curve(x, y) == true
    x = FieldElement.new(17, 223)
    y = FieldElement.new(56, 223)
    assert FieldElement.on_curve(x, y) == true
    x = FieldElement.new(200, 223)
    y = FieldElement.new(119, 223)
    assert FieldElement.on_curve(x, y) == false
    x = FieldElement.new(1, 223)
    y = FieldElement.new(193, 223)
    assert FieldElement.on_curve(x, y) == true
    x = FieldElement.new(42, 223)
    y = FieldElement.new(99, 223)
    assert FieldElement.on_curve(x, y) == false
  end
end
