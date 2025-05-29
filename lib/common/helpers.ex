defmodule Helpers do
  @moduledoc """
  Utility functions for binary manipulation, hex string validation, nonce generation,
  and network-related operations in a Bitcoin implementation.
  """

  @doc """
  Pads a binary with leading zeros to reach the specified size.

  ## Parameters
    - bin: Binary to pad.
    - size: Desired size in bytes (non-negative integer).

  ## Returns
    - Binary of `size` bytes with leading zeros if needed.
    - Raises ArgumentError if `size` is negative or `bin` is larger than `size`.

  ## Examples
      iex> Helpers.pad_binary(<<0xFF>>, 3)
      <<0, 0, 0xFF>>
  """
  def pad_binary(bin, size)
      when is_binary(bin) and is_integer(size) and size >= 0 do
    padding = size - byte_size(bin)

    if padding > 0 do
      <<0::size(padding * 8), bin::binary>>
    else
      bin
    end
  end

  def pad_binary(_bin, size), do: raise(ArgumentError, "Invalid size: #{size}")

  @doc """
  Reverses a binary, converting between big-endian and little-endian representations.

  ## Parameters
    - bin: Binary to reverse.

  ## Returns
    - Reversed binary.

  ## Examples
      iex> Helpers.reverse_binary(<<0x12, 0x34>>)
      <<0x34, 0x12>>
  """
  def reverse_binary(bin) when is_binary(bin) do
    bin |> :binary.bin_to_list() |> Enum.reverse() |> :erlang.list_to_binary()
  end

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

  def remove_leading_zeros(<<0, bin>>), do: remove_leading_zeros(bin)

  def remove_leading_zeros(bin) when is_binary(bin), do: bin

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
