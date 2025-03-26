defmodule CustomOperators do
  def a +++ b, do: FieldElement.add(a, b)
  def a --- b, do: FieldElement.sub(a, b)
  def a ||| b, do: FieldElement.mul(a, b)
  def a &&& b, do: FieldElement.div(a, b)
end
