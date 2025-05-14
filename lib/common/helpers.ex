defmodule Helpers do
  def pad_binary(bin, size) when is_binary(bin) do
    padding = size - byte_size(bin)

    if padding > 0 do
      <<0::size(padding * 8), bin::binary>>
    else
      bin
    end
  end

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

  def random_nonce() do
    k = Enum.random(0..(2 ** 64))
    MathUtils.int_to_little_endian(k, 8)
  end

  # IPV4 is 10 <<00>> bytes and 2 <<ff>> bytes then receiver ip
  def ip_v4(receiver_ip) do
    :binary.copy(<<0x00>>, 10) <> <<0xFF, 0xFF>> <> receiver_ip
  end
end
