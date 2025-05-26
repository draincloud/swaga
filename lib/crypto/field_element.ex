defmodule FieldElement do
  @moduledoc """
  Represents an element in a finite field for elliptic curve cryptography.
  Provides arithmetic operations (addition, subtraction, multiplication, division, exponentiation)
  and curve validation
  """
  @type t :: %__MODULE__{num: non_neg_integer(), prime: pos_integer()}
  # Always presented in the struct
  @enforce_keys [:num, :prime]
  # Define struct
  defstruct [:num, :prime]

  @doc """
  Checks if a point (x, y) lies on the secp256k1 curve: y^2 = x^3 + 7 mod p.

  ## Parameters
    - x: %FieldElement{} representing x-coordinate.
    - y: %FieldElement{} representing y-coordinate.

  ## Returns
    - true if the point is on the curve, false otherwise.

  ## Examples
      iex> x = FieldElement.new(1, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F)
      iex> y = FieldElement.new(2, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F)
      iex> FieldElement.on_curve(x, y)
      false
  """
  def on_curve(%FieldElement{num: x, prime: prime}, %FieldElement{num: y, prime: prime})
      when is_integer(x) and is_integer(y) do
    a = 0
    b = 7
    y3 = y ** 2
    x3 = x ** 3 + a * x + b
    Integer.mod(y3, prime) == Integer.mod(x3, prime)
  end

  def on_curve(%FieldElement{}, %FieldElement{}), do: {:error, :different_primes}

  @doc """
  Creates a new finite field element.

  ## Parameters
    - num: Non-negative integer less than prime.
    - prime: Positive integer (field modulus).

  ## Returns
    - %FieldElement{} on success.
    - {:error, reason} if invalid.

  ## Examples
      iex> FieldElement.new(5, 7)
      %FieldElement{num: 5, prime: 7}
  """
  def new(nil, prime), do: %FieldElement{num: nil, prime: prime}

  def new(num, prime) when is_integer(num) and is_integer(prime) and num <= prime and num >= 0,
    do: %FieldElement{num: num, prime: prime}

  def new(_, _), do: {:error, :invalid_field_element}

  @doc """
  Checks if two field elements are equal (same num and prime).

  ## Returns
    - true if equal, false otherwise.
  """
  def equal?(%FieldElement{num: num, prime: prime}, %FieldElement{num: num, prime: prime})
      when is_integer(num) and is_integer(prime),
      do: true

  def equal?(_, _), do: false

  @doc """
  Adds two field elements in the same field.

  ## Returns
    - %FieldElement{} on success.
    - {:error, reason} if primes differ or inputs are invalid.
  """
  def add(%FieldElement{num: num1, prime: prime}, %FieldElement{num: num2, prime: prime})
      when is_integer(num1) and is_integer(num2) do
    Integer.mod(num1 + num2, prime) |> new(prime)
  end

  def add(%FieldElement{}, %FieldElement{}), do: {:error, :different_primes}

  def sub(%FieldElement{num: num1, prime: prime}, %FieldElement{num: num2, prime: prime}) do
    sum = Integer.mod(num1 - num2, prime)
    new(sum, prime)
  end

  def sub(%FieldElement{}, %FieldElement{}) do
    raise ArgumentError, "Prime must be the same"
  end

  def mul(%FieldElement{num: num1, prime: prime}, %FieldElement{num: num2, prime: prime}) do
    sum = Integer.mod(num1 * num2, prime)
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

  @doc """
  Divides two field elements (num1 / num2 mod prime).

  ## Returns
    - %FieldElement{} on success.
    - {:error, reason} if primes differ or num2 is zero.
  """
  def div(%FieldElement{num: num1, prime: prime}, %FieldElement{num: num2, prime: prime})
      when is_integer(num1) and is_integer(num2) do
    pow_result = MathUtils.powmod(num2, prime - 2, prime)

    Integer.mod(num1 * pow_result, prime) |> new(prime)
  end

  def div(_, _), do: {:error, :invalid_field_element}
end
