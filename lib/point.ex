import CustomOperators
require Logger

defmodule Point do
  @enforce_keys [:x, :y, :a, :b]
  defstruct [:x, :y, :a, :b]

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
    y3 = FieldElement.pow(fe_y, 2)

    if fe_y.num == 0 do
      # Return the point at infinity
      %Point{x: nil, y: nil, a: a, b: b}
    else
      x_1_3 = FieldElement.pow(fe_x, 3)
      x_2_3 = a ||| fe_x
      x_3_3 = x_1_3 +++ x_2_3

      x3 =
          x_3_3 +++ b

      if FieldElement.equal?(y3, x3) == false do
        #      Logger.error("Error creating fe_x=#{inspect(fe_x)}, fe_y=#{inspect(fe_y)}")
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
    #        Logger.debug("s #{inspect(s)}")
    x3 = x_3 --- x2
    #        Logger.debug("x3 #{inspect(x3)}")
    sub_x = x1 --- x3
    #        Logger.debug("sub_x #{inspect(sub_x)}")
    y3 = s ||| sub_x
    #        Logger.debug("y3 #{inspect(y3)}")
    y3 = y3 --- y1
    #        Logger.debug("y1 #{inspect(y1)}")
    #        Logger.debug("y3 #{inspect(y3)}")
    if y3.num == 0 do
      # Return the point at infinity
      %Point{x: nil, y: nil, a: a, b: b}
    else
      %Point{x: x3, y: y3, a: a, b: b}
    end
  end

  # todo remove
  def add(%Point{x: p1_x, y: p1_y, a: a, b: b}, %Point{x: p2_x, y: p2_y, a: a, b: b})
      when p1_x != p2_x do
    cond do
      p1_x == nil ->
        %Point{x: p2_x, y: p2_y, a: a, b: b}

      p2_x == nil ->
        %Point{x: p1_x, y: p1_y, a: a, b: b}

      true ->
        s = (p2_y - p1_y) / (p2_x - p1_x)
        p3_x = s ** 2 - p1_x - p2_x
        p3_y = s * (p1_x - p3_x) - p1_y
        %Point{x: p3_x, y: p3_y, a: a, b: b}
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
    a = 5
    b = 7

    if y.num == 0 do
      %Point{x: nil, y: nil, a: a, b: b}
    else
      Logger.debug("x #{inspect(x)}; a #{inspect(a)}")
      divisor_y = y ||| 2
      dividend_s =
          FieldElement.pow(x, 2) ||| 3 +++ a
      s = dividend_s &&& divisor_y
      pow_s = FieldElement.pow(s, 2)
      mul_x = x ||| 2
      x3 = pow_s --- mul_x
      # todo continue
      y3 = s * (x - x3) - y
      %Point{x: x3, y: y3, a: a, b: b}
    end
  end

  def add(%Point{}, %Point{}) do
    raise ArgumentError, "Points are not on the same curve"
  end

  # Public API for multiplying a point by a scalar
  def mul(point, coefficient) when is_integer(coefficient) do
    do_mul(point, coefficient, %Point{x: nil, y: nil, a: point.a, b: point.b})
  end

  # Private recursive function that implements double-and-add
  defp do_mul(_point, 0, result), do: result

  defp do_mul(point, coef, result) do
    new_result =
      if Bitwise.band(coef, 1) == 1 do
        # todo fix
        add(result, point)
      else
        result
      end

    # Doubling the point
    new_point = add(point, point)
    do_mul(new_point, Bitwise.bsr(coef, 1), new_result)
  end
end
