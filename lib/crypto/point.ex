import CustomOperators

defmodule Point do
  @enforce_keys [:x, :y, :a, :b]
  defstruct [:x, :y, :a, :b]

  def new(
        fe_x,
        fe_y,
        fe_a,
        fe_b
      )
      when fe_x.num == nil and fe_y.num == nil do
    %Point{x: nil, y: nil, a: fe_a, b: fe_b}
  end

  def new(
        nil,
        nil,
        fe_a,
        fe_b
      ) do
    %Point{x: nil, y: nil, a: fe_a, b: fe_b}
  end

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
      x_1_3 = FieldElement.pow(fe_x, 3)
      x_2_3 = a ||| fe_x
      x_3_3 = x_1_3 +++ x_2_3

      x3 =
        x_3_3 +++ b

      if FieldElement.equal?(y3, x3) == false do
        raise ArgumentError, "Cannot create a point, y3 != x3"
      else
        %Point{x: fe_x, y: fe_y, a: a, b: b}
      end
    end
  end

  def equals?(%Point{x: x, y: y, a: a, b: b}, %Point{x: x, y: y, a: a, b: b}),
    do: true

  def equals?(_, _), do: false

  def add(p1, p2) when p1.x == nil, do: p2
  def add(p1, p2) when p2.x == nil, do: p1

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
    raise ArgumentError, "Points are not on the same curve"
  end

  def mul(point, coefficient) when is_integer(coefficient) do
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
