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
end
