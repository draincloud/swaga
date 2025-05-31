defmodule Binary.Common do
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
      iex> Binary.Common.reverse_binary(<<0x12, 0x34>>)
      <<0x34, 0x12>>
  """
  def reverse_binary(bin) when is_binary(bin) do
    bin |> :binary.bin_to_list() |> Enum.reverse() |> :erlang.list_to_binary()
  end

  def remove_leading_zeros(<<0, bin>>), do: remove_leading_zeros(bin)

  def remove_leading_zeros(bin) when is_binary(bin), do: bin
end
