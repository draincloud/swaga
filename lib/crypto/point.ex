defmodule Point do
  import CustomOperators

  @moduledoc """
  Represents a point on the elliptic curve
  Provides operations for point addition and scalar multiplication.
  The point at infinity is represented as x: nil, y: nil.
  """

  @enforce_keys [:x, :y, :a, :b]
  defstruct [:x, :y, :a, :b]

  @type t :: %__MODULE__{
          x: FieldElement.t() | nil,
          y: FieldElement.t() | nil,
          a: FieldElement.t(),
          b: FieldElement.t()
        }
  @doc """
  Creates a new point on an elliptic curve y^2 = x^3 + ax + b mod p.

  ## Parameters
    - x: %FieldElement{} or nil (for point at infinity).
    - y: %FieldElement{} or nil (for point at infinity).
    - a: %FieldElement{} representing curve parameter a.
    - b: %FieldElement{} representing curve parameter b.

  ## Returns
    - %Point{} if valid and on curve.
    - {:error, reason} if invalid or not on curve.
  """
  def new(
        fe_x,
        fe_y,
        fe_a,
        fe_b
      )
      when fe_x.num == nil and fe_y.num == nil,
      do: %Point{x: nil, y: nil, a: fe_a, b: fe_b}

  def new(
        nil,
        nil,
        fe_a,
        fe_b
      )
      when is_struct(fe_a, FieldElement) and is_struct(fe_b, FieldElement),
      do: %Point{x: nil, y: nil, a: fe_a, b: fe_b}

  def new(
        fe_x,
        fe_y,
        a,
        b
      ) do
    if fe_y.num == 0 do
      # Return the point at infinity
      %Point{x: nil, y: nil, a: a, b: b}
    else
      y3 = FieldElement.pow(fe_y, 2)

      x3 = FieldElement.pow(fe_x, 3) +++ (a ||| fe_x) +++ b

      if FieldElement.equal?(y3, x3) == false do
        {:error, :y3_not_equal_x3}
      else
        %Point{x: fe_x, y: fe_y, a: a, b: b}
      end
    end
  end

  @doc """
  Checks if two points are equal (same x, y, a, b).

  ## Returns
    - true if equal, false otherwise.
  """
  def equals?(%Point{x: x, y: y, a: a, b: b}, %Point{x: x, y: y, a: a, b: b}),
    do: true

  def equals?(_, _), do: false

  @doc """
  Adds two points on the same elliptic curve.

  ## Returns
    - %Point{} on success.
    - {:error, reason} if invalid.
  """
  def add(%Point{x: nil, y: nil}, p) when is_struct(p, Point), do: p
  def add(p, %Point{x: nil, y: nil}) when is_struct(p, Point), do: p

  def add(
        %Point{
          x: x1,
          y: y1,
          a: a,
          b: b
        },
        %Point{
          x: x2,
          y: y2,
          a: a,
          b: b
        }
      )
      when x1 != x2 do
    s = y2 --- y1 &&& x2 --- x1
    pow_s = FieldElement.pow(s, 2)
    x_3 = pow_s --- x1
    x3 = x_3 --- x2
    sub_x = x1 --- x3
    y3 = s ||| sub_x
    y3 = y3 --- y1

    if y3.num == 0 do
      # Return the point at infinity
      %Point{x: nil, y: nil, a: a, b: b}
    else
      %Point{x: x3, y: y3, a: a, b: b}
    end
  end

  # two points are additive inverses -> we return infinity point (x are the same)
  def add(
        %Point{
          x: x1,
          y: y1,
          a: a,
          b: b
        },
        %Point{
          x: x2,
          y: y2,
          a: a,
          b: b
        }
      )
      when x1 == x2 and y1 != y2 do
    %Point{x: nil, y: nil, a: a, b: b}
  end

  #  Point Addition for When P1 = P2
  def add(
        %Point{
          x: x,
          y: y,
          a: a,
          b: b
        },
        %Point{
          x: x,
          y: y,
          a: a,
          b: b
        }
      ) do
    if y.num == 0 do
      %Point{x: nil, y: nil, a: a, b: b}
    else
      divisor_y = y ||| FieldElement.new(2, y.prime)

      dividend_s =
        FieldElement.pow(x, 2) ||| FieldElement.new(3, x.prime) +++ a

      s = dividend_s &&& divisor_y
      pow_s = FieldElement.pow(s, 2)
      mul_x = x ||| FieldElement.new(2, x.prime)
      x3 = pow_s --- mul_x
      y3 = (s ||| x --- x3) --- y
      %Point{x: x3, y: y3, a: a, b: b}
    end
  end

  def add(%Point{}, %Point{}) do
    {:error, :points_not_on_the_same_curve}
  end

  @doc """
  Performs scalar multiplication of a point by an integer.

  ## Parameters
    - point: %Point{} on the elliptic curve.
    - coefficient: Non-negative integer scalar.

  ## Returns
    - %Point{} on success.
    - {:error, reason} if invalid.
  """
  def mul(point, coefficient)
      when is_integer(coefficient) and is_struct(point, Point) and coefficient >= 0 do
    mul(point, coefficient, %Point{x: nil, y: nil, a: point.a, b: point.b})
  end

  defp mul(_point, 0, result) do
    result
  end

  defp mul(point, coefficient, result) do
    result =
      if Bitwise.band(coefficient, 1) == 1 do
        add(result, point)
      else
        result
      end

    # double the point
    point = add(point, point)
    # shift coefficient right by 1
    coefficient = Bitwise.bsr(coefficient, 1)
    mul(point, coefficient, result)
  end
end
