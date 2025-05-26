defmodule Base58 do
  @moduledoc """
  Implements Base58 and Base58Check encoding/decoding for Bitcoin addresses, keys, and other data.
  Follows Bitcoin's conventions, including leading zeros and 4-byte checksums.
  """
  @base58_alphabet "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"

  def div_mod(a, b) when is_integer(a) and is_integer(b) and b > 0 do
    {div(a, b), rem(a, b)}
  end

  @doc """
  Counts leading zero bytes in a binary.

  ## Returns
    - Number of leading zeros (non-negative integer).

  ## Examples
      iex> Base58.count_zeros(<<0, 0, 0xFF>>)
      2
      iex> Base58.count_zeros(<<0xFF>>)
      0
  """
  def count_zeros(<<0, bin::binary>>), do: 1 + count_zeros(bin)
  def count_zeros(<<_, _::binary>>), do: 0
  def count_zeros(<<>>), do: 0

  @doc """
  Encodes a non-negative integer to a Base58 string.

  ## Parameters
    - num: Non-negative integer to encode.
    - acc: Accumulator for recursion (default: []).

  ## Returns
    - Base58-encoded string.

  ## Examples
      iex> Base58.encode_num(123)
      "2c"
  """
  def encode_num(num, acc \\ [])
  def encode_num(0, acc), do: Enum.join(acc)

  def encode_num(num, acc) when is_integer(num) and num > 0 do
    {num, mod} = div_mod(num, 58)
    encode_num(num, [String.at(@base58_alphabet, mod) | acc])
  end

  @doc """
  Encodes a binary to a Base58 string, preserving leading zeros as "1"s.

  ## Parameters
    - binary: Binary to encode.

  ## Returns
    - Base58-encoded string.

  ## Examples
      iex> Base58.encode_from_binary(<<0, 0, 0xFF>>)
      "112m"
  """
  def encode_from_binary(<<>>), do: ""

  def encode_from_binary(binary) do
    zeros_len = count_zeros(binary)
    num = :binary.decode_unsigned(binary, :big)
    prefix = String.duplicate("1", zeros_len)
    prefix <> encode_num(num)
  end

  @doc """
  Encodes a binary to Base58Check, appending a 4-byte checksum (first 4 bytes of double SHA-256).

  ## Parameters
    - binary: Binary to encode (e.g., 21-byte address payload).

  ## Returns
    - Base58Check-encoded string.

  ## Examples
      iex> Base58.encode_base58_checksum(<<0x00, 0xFF::160>>)
      "1QLbz7JHiBTspS962RLKV8GndWFwi5j6Qr"
  """
  def encode_base58_checksum(binary) when is_binary(binary) and byte_size(binary) > 0 do
    checksum = :crypto.hash(:sha256, :crypto.hash(:sha256, binary)) |> binary_part(0, 4)
    encode_from_binary(binary <> checksum)
  end

  @doc """
  Decodes a Base58Check string, validates the checksum, and extracts the payload.

  ## Parameters
    - s: Base58Check-encoded string.

  ## Returns
    - {:ok, binary()} if valid, where binary is the payload (e.g., 20-byte address hash).
    - {:error, reason} if invalid.

  ## Examples
      iex> Base58.decode("1QLbz7JHiBTspS962RLKV8GndWFwi5j6Qr")
      {:ok, <<0xFF, ...>>}
  """
  def decode(s) when is_binary(s) do
    num =
      s
      |> String.graphemes()
      |> Enum.reduce(0, fn c, acc ->
        acc = acc * 58
        {index, _} = :binary.match(@base58_alphabet, c)
        acc + index
      end)

    combined = :binary.encode_unsigned(num, :big)

    # Ensure that the length is 25
    padded_combined =
      :binary.copy(<<0>>, 25 - byte_size(combined)) <> combined

    <<payload::binary-size(byte_size(padded_combined) - 4), checksum::binary-size(4)>> =
      padded_combined

    <<first_4_bytes::binary-size(4), _::binary>> =
      CryptoUtils.double_hash256(payload)
      |> :binary.encode_unsigned(:big)
      |> Helpers.pad_binary(byte_size(payload))

    if first_4_bytes != checksum do
      raise "bad address, checksum is incorrect"
    else
      # First byte is the network prefix, the middle 20 are actual address
      <<_first_byte::binary-size(1), result::binary-size(20), _checksum::binary-size(4)>> =
        padded_combined

      Base.encode16(result, case: :lower)
    end
  end
end
