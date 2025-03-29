require Logger
import Bitwise

defmodule Signature do
  @enforce_keys [:r, :s]
  defstruct [:r, :s]

  def new(r, s) do
    %Signature{r: r, s: s}
  end

  def strip_leading_zeros(<<0, rest>>), do: strip_leading_zeros(rest)
  def strip_leading_zeros(bin), do: bin

  def der(%Signature{r: r, s: s}) do
    rbin = :binary.encode_unsigned(r, :big)
    rbin = strip_leading_zeros(rbin)
    #    Logger.debug("rbin #{inspect(rbin)}")
    <<first_byte, _::binary>> = rbin

    rbin =
      if (first_byte &&& 0x80) != 0 do
        <<0::size(8)>> <> rbin
      else
        rbin
      end

    result = <<2, byte_size(rbin)>> <> rbin
    sbin = :binary.encode_unsigned(s, :big)
    sbin = strip_leading_zeros(sbin)
    <<first_byte, _::binary>> = sbin

    sbin =
      if (first_byte &&& 0x80) != 0 do
        <<0::size(8)>> <> sbin
      else
        sbin
      end

    result = result <> <<2, byte_size(sbin)>> <> sbin
    <<0x30, byte_size(result)>> <> result
  end
end
