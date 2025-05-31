defmodule Helpers do
  @moduledoc """
  Utility functions for binary manipulation, hex string validation, nonce generation,
  and network-related operations in a Bitcoin implementation.
  """

  @doc """
  Checks if a string is a valid hex string (0-9, a-f, A-F) with even length.

  ## Parameters
    - str: String to check.

  ## Returns
    - true if valid, false otherwise.

  ## Examples
      iex> Helpers.is_hex_string?("1a2b3c")
      true
      iex> Helpers.is_hex_string?("1a2b3")
      false
  """
  def is_hex_string?(str) when is_binary(str) do
    Regex.match?(~r/^[0-9a-fA-F]+$/, str) and rem(byte_size(str), 2) == 0
  end

  @doc """
  Generates a random 8-byte nonce in little-endian format.

  ## Returns
    - 8-byte binary nonce.

  ## Examples
      iex> byte_size(Helpers.random_nonce())
      8
  """
  def random_nonce() do
    k = Enum.random(0..(2 ** 64))
    MathUtils.int_to_little_endian(k, 8)
  end

  @doc """
  Generates a random 8-byte nonce in little-endian format.

  ## Returns
    - 8-byte binary nonce.

  ## Examples
      iex> byte_size(Helpers.random_nonce())
      8
  """
  def ip_v4(receiver_ip) when is_binary(receiver_ip) and byte_size(receiver_ip) == 4 do
    :binary.copy(<<0x00>>, 10) <> <<0xFF, 0xFF>> <> receiver_ip
  end

  def ip_v4(_), do: raise(ArgumentError, "Invalid IPv4 address")
end
