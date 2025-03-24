defmodule Point do
  @enforce_keys [:x, :y, :a, :b]
  defstruct [:x, :y, :a, :b]

  # y^2 = x^3 + ax + b
  # For secp256k1 a = 5, b = 7
  def new(x, y, a, b) when y * y != x * x * x + a * x + b do
    raise ArgumentError, "Cannot create a point"
  end

  def new(x, y, a, b) do
    %Point{x: x, y: y, a: a, b: b}
  end

  def equals?(%Point{x: x, y: y, a: a, b: b}, %Point{x: x, y: y, a: a, b: b}),
    do: true

  def equals?(_, _), do: false

  def add(%Point{x: p1_x, y: p1_y, a: a, b: b}, %Point{x: p2_x, y: p2_y, a: a, b: b}) do
    case p1_x == nil do
      true -> %Point{x: p2_x, y: p2_y, a: a, b: b}
    end
    case p2_x == nil do
      true -> %Point{x: p1_x, y: p1_y, a: a, b: b}
    end
  end

  # two points are additive inverses -> we return infinity point
  def add(%Point{x: x, y: p1_y, a: a, b: b}, %Point{x: x, y: p2_y, a: a, b: b}) do
    %Point{x: nil, y: nil, a: a, b: b}
  end

  def add(%Point{}, %Point{}) do
    raise ArgumentError, "Points are not on the same curve"
  end
end
