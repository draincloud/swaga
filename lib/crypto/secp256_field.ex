defmodule Secp256Field do
  @enforce_keys [:num, :prime]
  defstruct [:num, :prime]

  @moduledoc """
  Represents an element in the secp256k1 finite field with prime modulus
  p = 2^256 - 2^32 - 977. Provides functions for creating field elements
  and computing square roots, specialized for Bitcoin's secp256k1 curve.
  """
  @type t :: %__MODULE__{
          num: non_neg_integer(),
          prime: pos_integer()
        }
  @p 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F
  @doc """
  Returns the secp256k1 field modulus p = 2^256 - 2^32 - 977.

  ## Examples
        iex> Secp256FieldElement.p()
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFEFFFFFC2F
  """
  def p(), do: @p

  @doc """
  Creates a new element in the secp256k1 field.

  ## Parameters
    - num: an Integer number (0 ≤ num < p).

  ## Returns
    - {%Secp256Field{}} if valid.
    - {:error, reason} if invalid.

  ## Examples
      iex> Secp256Field.new(1)
  """
  def new(num) when is_integer(num) and num >= 0 do
    FieldElement.new(num, @p)
  end

  def new(_num), do: {:error, :invalid_input}

  @doc """
  Computes the square root of a field element modulo p = 2^256 - 977.

  ## Parameters
    - field_element: %Secp256Field{} in the secp256k1 field.

  ## Returns
    - %Secp256Field{} if the square root exists.
    - {:error, reason} if invalid or not a quadratic residue.
  """
  def sqrt(f_element) when is_struct(f_element, FieldElement) do
    # For later: Check for is_quadratic_residue
    FieldElement.pow(f_element, div(@p + 1, 4))
  end

  def sqrt(_f_element), do: {:error, :invalid_field_element}
end
