defmodule FieldElement do
  # Always presented in the struct
  @enforce_keys [:num, :prime]
  # Define struct
  defstruct [:num, :prime]

  def new(num, prime) when num >= prime or num < 0 do
    raise ArgumentError, "Cannot create field_element"
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
    sum = rem(num1 + num2, prime)
    new(sum, prime)
  end

  def add(%FieldElement{}, %FieldElement{}) do
    raise ArgumentError, "Prime must be the same"
  end

  def sub(%FieldElement{num: num1, prime: prime}, %FieldElement{num: num2, prime: prime}) do
    sum = rem(num1 - num2, prime)
    new(sum, prime)
  end

  def sub(%FieldElement{}, %FieldElement{}) do
    raise ArgumentError, "Prime must be the same"
  end

  def mul(%FieldElement{num: num1, prime: prime}, %FieldElement{num: num2, prime: prime}) do
    sum = rem(num1 * num2, prime)
    new(sum, prime)
  end

  def mul(%FieldElement{}, %FieldElement{}) do
    raise ArgumentError, "Prime must be the same"
  end

  #  the exponent doesn’t have to be a member of the finite field for the math to work
  def pow(%FieldElement{num: num, prime: prime}, exponent) do
    # exp % (p - 1) based on Fermat’s little theorem
    n = Integer.mod(exponent, prime - 1)
    num = Integer.mod(num ** n, prime)
    new(num, prime)
  end

  def div(%FieldElement{num: num1, prime: prime}, %FieldElement{num: num2, prime: prime}) do
    div_result = rem(num1 * num2 ** (prime - 2), prime)
    new(div_result, prime)
  end

  def div(%FieldElement{}, %FieldElement{}) do
    raise ArgumentError, "Prime must be the same"
  end
end
