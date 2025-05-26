defmodule Signature do
  import Bitwise

  @moduledoc """
  Represents an ECDSA signature for Bitcoin's secp256k1 curve, with components r and s.
  Provides functions to create signatures, encode them in DER format, and parse DER-encoded signatures.
  """
  @type t :: %__MODULE__{
          r: pos_integer(),
          s: pos_integer()
        }
  @enforce_keys [:r, :s]
  defstruct [:r, :s]

  @doc """
  Creates a new ECDSA signature.

  ## Parameters
    - r: Integer signature component (0 < r < n).
    - s: Integer signature component (0 < s < n).

  ## Returns
    - %Signature{} if valid.
    - {:error, reason} if invalid.

  ## Examples
      iex> Signature.new(1, 2)
      %Signature{r: 1, s: 2}
  """
  def new(r, s) when is_integer(r) and is_integer(s) and r > 0 and s > 0 do
    n = Secp256Point.n()

    if r >= n or s >= n do
      {:error, :invalid_signature_components}
    else
      %Signature{r: r, s: s}
    end
  end

  def new(_r, _s), do: {:error, :invalid_input}

  @doc """
  Removes leading zero bytes from a binary.

  ## Parameters
    - bin: Binary to strip.

  ## Returns
    - Binary with leading zeros removed.
  """
  def strip_leading_zeros(<<0, rest>>), do: strip_leading_zeros(rest)
  def strip_leading_zeros(bin), do: bin

  @doc """
  Encodes an ECDSA signature in DER format per Bitcoin's specification.

  ## Parameters
    - signature: %Signature{} with r, s components.

  ## Returns
    - binary() with DER-encoded signature.
    - {:error, reason} if invalid.
  """
  def der(%Signature{r: r, s: s}) when is_integer(r) and is_integer(s) do
    rbin = <<first_byte, _::binary>> = r |> :binary.encode_unsigned(:big) |> strip_leading_zeros

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

  def der(_sig), do: {:error, :invalid_signature}

  @doc """
  Parses a DER-encoded ECDSA signature into a Signature struct.

  ## Parameters
    - der: Binary in DER format.

  ## Returns
    - %Signature{} if valid.
    - {:error, reason} if invalid.
  """
  def parse(<<0x30, length, signature_bin::binary>> = der) do
    {:ok} = verify_sig_len(der, length)

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

    if byte_size(der) != 6 + r_len + s_len do
      raise "Signature too long #{byte_size(der)}"
    end

    Signature.new(r, s)
  end

  defp verify_sig_len(der, length) when is_binary(der) and is_integer(length) do
    if length + 2 != byte_size(der) do
      {:error, :bad_signature}
    else
      {:ok}
    end
  end
end
