require Logger

defmodule FieldElement do
  # Always presented in the struct
  @enforce_keys [:num, :prime]
  # Define struct
  defstruct [:num, :prime]

  # Check for (x, y), a = 0, b = 7
  def on_curve(%FieldElement{num: x, prime: prime}, %FieldElement{num: y, prime: prime}) do
    a = 0
    b = 7
    y3 = y ** 2
    x3 = x ** 3 + a * x + b
    Integer.mod(y3, prime) == Integer.mod(x3, prime)
  end

  def on_curve(%FieldElement{}, %FieldElement{}) do
    raise ArgumentError, "Not on curve, different prime"
  end

  def new(nil, prime) do
    %FieldElement{num: nil, prime: prime}
  end

  def new(num, prime) when num >= prime or num < 0 do
    raise ArgumentError,
          "Cannot create field_element num=#{inspect(num)}, prime=#{inspect(prime)}"
  end

  def new(num, prime) do
    %FieldElement{num: num, prime: prime}
  end

  # First we bind num -> num, prime -> prime
  # Secondly we check already bounded num -> num, bounded prime -> prime
  def equal?(%FieldElement{num: num, prime: prime}, %FieldElement{num: num, prime: prime}),
    do: true

  def equal?(%FieldElement{}, %FieldElement{}), do: false
  def equal?(_, _), do: false

  def not_equal?(%FieldElement{num: num, prime: prime}, %FieldElement{num: num, prime: prime}),
    do: false

  def not_equal?(%FieldElement{}, %FieldElement{}), do: true
  def not_equal?(_, _), do: false

  def add(%FieldElement{num: num1, prime: prime}, %FieldElement{num: num2, prime: prime}) do
    sum = Integer.mod(num1 + num2, prime)
    new(sum, prime)
  end

  def add(%FieldElement{}, %FieldElement{}) do
    raise ArgumentError, "Prime must be the same"
  end

  def sub(%FieldElement{num: num1, prime: prime}, %FieldElement{num: num2, prime: prime}) do
    sum = Integer.mod(num1 - num2, prime)
    new(sum, prime)
  end

  def sub(%FieldElement{}, %FieldElement{}) do
    raise ArgumentError, "Prime must be the same"
  end

  def mul(%FieldElement{num: num1, prime: prime}, %FieldElement{num: num2, prime: prime}) do
    sum = Integer.mod(num1 * num2, prime)
    #    Logger.debug("sum #{inspect(num1)} * #{inspect(num2)} = #{inspect(sum)}")
    new(sum, prime)
  end

  def mul(%FieldElement{}, %FieldElement{}) do
    raise ArgumentError, "Prime must be the same"
  end

  #  the exponent doesn’t have to be a member of the finite field for the math to work
  def pow(%FieldElement{num: num, prime: prime}, exponent) do
    # exp % (p - 1) based on Fermat’s little theorem
    n = Integer.mod(exponent, prime - 1)
    num = MathUtils.powmod(num, n, prime)
    new(num, prime)
  end

  def div(%FieldElement{num: num1, prime: prime}, %FieldElement{num: num2, prime: prime}) do
    #    Logger.debug("num1 #{inspect(num1)}; num2 #{inspect(num2)}")
    pow_result = MathUtils.powmod(num2, prime - 2, prime)
    #    Logger.debug("pow_result #{inspect(pow_result)};")

    div_result = Integer.mod(num1 * pow_result, prime)
    #    Logger.debug("div_result #{inspect(div_result)};")
    new(div_result, prime)
  end

  def div(%FieldElement{}, %FieldElement{}) do
    raise ArgumentError, "Prime must be the same"
  end
end
