defmodule Helpers do
  def reverse_binary(bin) when is_binary(bin) do
    bin |> :binary.bin_to_list() |> Enum.reverse() |> :erlang.list_to_binary()
  end

  def is_hex_string?(str) when is_binary(str) do
    Regex.match?(~r/^[0-9a-fA-F]+$/, str) and rem(byte_size(str), 2) == 0
  end

  def remove_leading_zeros(<<0, str>>) do
    remove_leading_zeros(str)
  end

  def remove_leading_zeros(str) do
    str
  end
end
