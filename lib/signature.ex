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

  def parse(full_sig) do
    <<first_compound, signature_bin::binary>> = full_sig

    if first_compound != 0x30 do
      raise "Bad signature first_compound equals #{inspect(first_compound)}"
    end

    <<length, signature_bin::binary>> = signature_bin

    if length + 2 != byte_size(full_sig) do
      raise "Bad signature length equals #{length + 2}, should be #{div(bit_size(signature_bin), 8)}"
      raise "Bad signature length equals #{length + 2}, should be #{bit_size(signature_bin)}"
    else
    end

    <<marker, signature_bin::binary>> = signature_bin

    if marker != 0x02 do
      raise "Bad marker equals #{marker}"
    end

    <<r_len, signature_bin::binary>> = signature_bin
    <<r::binary-size(r_len), signature_bin::binary>> = signature_bin

    <<marker, signature_bin::binary>> = signature_bin

    if marker != 0x02 do
      raise "Bad marker equals #{marker}"
    end

    <<s_len, signature_bin::binary>> = signature_bin
    <<s::binary-size(s_len), _::binary>> = signature_bin

    s = :binary.decode_unsigned(s, :big)
    r = :binary.decode_unsigned(r, :big)

    if byte_size(full_sig) != 6 + r_len + s_len do
      raise "Signature too long #{byte_size(full_sig)}"
    end

    Signature.new(r, s)
  end
end
