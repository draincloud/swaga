defmodule MathUtils do
  @moduledoc """
  Provides various mathematical utility functions.

  Includes functions for modular exponentiation and
  handling little-endian integer-to-binary conversions,
  often needed in cryptographic or low-level protocol implementations.
  """

  @doc """
  Calculates modular exponentiation: `(n ^ k) % m`.

  This is an efficient way to compute powers within a modulus,
  avoiding large intermediate numbers. It uses the "exponentiation by squaring"
  method.

  ## Parameters
    - n: The base.
    - k: The exponent.
    - m: The modulus.

  ## Returns
    - The integer result of `(n ^ k) % m`.

  ## Examples
      iex> MathUtils.powmod(2, 10, 1024)
      0
      iex> MathUtils.powmod(3, 4, 5)
      1 # (3^4 = 81, 81 % 5 = 1)
  """
  def powmod(n, k, m), do: do_powmod(n, k, m, 1)
  # Base case: exponent is 0, result is the accumulator `r`.
  defp do_powmod(_, 0, _, r), do: r

  # Recursive step for modular exponentiation.
  defp do_powmod(n, k, m, r) do
    # If k is odd, multiply r by n (mod m).
    r_new = if rem(k, 2) == 1, do: rem(r * n, m), else: r
    # Square n (mod m).
    n_new = rem(n * n, m)
    # Halve k (integer division).
    k_new = div(k, 2)
    # Recurse.
    do_powmod(n_new, k_new, m, r_new)
  end

  @doc """
  Converts a binary string (interpreted as little-endian) to an integer.

  ## Parameters
    - binary_data: A binary string.

  ## Returns
    - The corresponding integer.

  ## Examples
      iex> MathUtils.little_endian_to_int(<<1, 0, 0, 0>>)
      1
      iex> MathUtils.little_endian_to_int(<<0, 1, 0, 0>>)
      256
  """
  def little_endian_to_int(binary_data) when is_binary(binary_data) do
    :binary.decode_unsigned(binary_data, :little)
  end

  @doc """
  Converts an integer to a binary string of a specific length using
  little-endian encoding.

  It uses Elixir's binary constructor for a concise and efficient conversion.
  If the integer is too large to fit in `length` bytes, an `ArgumentError`
  will be raised.

  ## Parameters
    - num: The integer to convert.
    - length: The desired length of the output binary in bytes.

  ## Returns
    - A binary string of the specified `length`.

  ## Examples
      iex> MathUtils.int_to_little_endian(1, 4)
      <<1, 0, 0, 0>>
      iex> MathUtils.int_to_little_endian(256, 4)
      <<0, 1, 0, 0>>
      iex> MathUtils.int_to_little_endian(10, 2)
      <<10, 0>>
  """
  def int_to_little_endian(num, length) when is_integer(num) and is_integer(length) do
    bin = :binary.encode_unsigned(num, :little)
    padding = length - byte_size(bin)

    if padding < length do
      bin <> :binary.copy(<<0>>, padding)
    else
      bin
    end
  end
end
