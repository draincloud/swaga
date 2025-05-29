defmodule Secp256Point do
  import CustomOperators

  @moduledoc """
  Represents a point on Bitcoin's secp256k1 elliptic curve (y^2 = x^3 + 7 mod p).
  Provides functions for point creation, ECDSA signature verification, SEC format
  encoding/decoding, and Bitcoin address generation.
  """
  @type t :: %__MODULE__{
          x: Secp256Field.t() | nil,
          y: Secp256Field.t() | nil,
          a: Secp256Field.t(),
          b: Secp256Field.t()
        }

  @enforce_keys [:x, :y, :a, :b]
  defstruct [:x, :y, :a, :b]
  @n 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141
  @g_x 0x79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798
  @g_y 0x483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8
  @a 0
  @b 7

  def b do
    @b
  end

  def n do
    @n
  end

  @doc """
  Creates a new point on the secp256k1 curve.

  ## Parameters
    - x: Integer or %Secp256Field{} (x-coordinate).
    - y: Integer or %Secp256Field{} (y-coordinate).

  ## Returns
    - %Secp256Point{} if valid and on curve.
    - {:error, reason} if invalid or not on curve.
  """
  def new(x, y) when is_integer(x) and is_integer(y) do
    a = Secp256Field.new(@a)
    b = Secp256Field.new(@b)
    Point.new(Secp256Field.new(x), Secp256Field.new(y), a, b)
  end

  # Case when we pass field element instead of numbers
  def new(%FieldElement{} = x, %FieldElement{} = y) do
    a = Secp256Field.new(@a)
    b = Secp256Field.new(@b)
    Point.new(x, y, a, b)
  end

  def new(_x, _y), do: {:error, :invalid_coordinates}

  def new(x, y, a, b) do
    a = Secp256Field.new(a)
    b = Secp256Field.new(b)
    Point.new(x, y, a, b)
  end

  @doc """
  Returns the secp256k1 generator point G.

  ## Returns
    - %Secp256Point{} representing G.
  """
  def get_g() do
    new(@g_x, @g_y)
  end

  @doc """
  Performs scalar multiplication of a secp256k1 point by a coefficient.

  ## Parameters
    - point: %Secp256Point{} on the secp256k1 curve.
    - coefficient: Integer or binary scalar.

  ## Returns
    - %Secp256Point{} on success.
    - {:error, reason} if invalid.
  """
  def mul(point, coefficient)
      when is_integer(coefficient) and is_integer(coefficient) and coefficient >= 0 do
    coefficient = rem(coefficient, @n)
    Point.mul(point, coefficient)
  end

  def mul(point, coefficient) when is_binary(coefficient) do
    mul(point, :binary.decode_unsigned(coefficient))
  end

  def mul(_point, _coefficient), do: {:error, :invalid_input}

  @doc """
  Verifies an ECDSA signature for a message hash.

  ## Parameters
    - point: %Secp256Point{} (public key).
    - z: 256-bit integer (message hash).
    - sig: %Signature{} with r, s components.

  ## Returns
    - boolean() indicating if the signature is valid.
    - {:error, reason} if invalid.
  """
  def verify(point, z, %{r: r, s: s})
      when is_integer(z) and z >= 0 and is_integer(r) and is_integer(s) do
    # s_inv (1/s) is calculated using Fermat’ little theorem on the order of the group,
    # n, which is prime.
    s_inv = MathUtils.powmod(s, @n - 2, @n)
    # u = z/s. Note that we can mod by n as that’s the order of the group.
    u = rem(z * s_inv, @n)
    # v = r/s. Note that we can mod by n as that’s the order of the group.
    v = rem(r * s_inv, @n)
    g = get_g()
    #    uG + vP should be R.
    total = Point.add(mul(g, u), mul(point, v))
    total.x.num == r
  end

  @doc """
  Encodes a secp256k1 point in uncompressed SEC format (04|x|y).

  ## Returns
    - binary() with 65-byte SEC encoding.
    - {:error, reason} if invalid.
  """
  def uncompressed_sec(%{
        x: %FieldElement{num: num_x},
        y: %FieldElement{num: num_y}
      }) do
    <<4>> <>
      <<num_x::unsigned-big-integer-size(256)>> <>
      <<num_y::unsigned-big-integer-size(256)>>
  end

  def uncompressed_sec(_point), do: {:error, :invalid_point}

  @doc """
  Encodes a secp256k1 point in compressed SEC format (02|x or 03|x).

  ## Returns
    - binary() with 33-byte SEC encoding.
    - {:error, reason} if invalid.
  """
  def compressed_sec(%{point: %{x: %{num: x}, y: %{num: y}}}) do
    case rem(y, 2) == 0 do
      true -> <<2>> <> <<x::unsigned-big-integer-size(256)>>
      false -> <<3>> <> <<x::unsigned-big-integer-size(256)>>
    end
  end

  def compressed_sec(%{x: %{num: x}, y: %{num: y}}) do
    case rem(y, 2) == 0 do
      true -> <<2>> <> <<x::unsigned-big-integer-size(256)>>
      false -> <<3>> <> <<x::unsigned-big-integer-size(256)>>
    end
  end

  def compressed_sec(_point), do: {:error, :invalid_point}

  @doc """
  Parses a SEC-encoded public key into a secp256k1 point.

  ## Parameters
    - sec_bin: Binary in uncompressed (04|x|y) or compressed (02|x or 03|x) format.

  ## Returns
    - {:ok, %Secp256Point{}} if valid.
    - {:error, reason} if invalid.
  """
  def parse(sec_bin = <<4, _rem::binary>>) do
    <<_prefix, num_bytes::binary-size(32), num_bytes_rest::binary>> = sec_bin

    new(
      :binary.decode_unsigned(num_bytes, :big),
      :binary.decode_unsigned(num_bytes_rest, :big)
    )
  end

  def parse(<<prefix, x_num::binary>>) when prefix in [2, 3] do
    x = Secp256Field.new(:binary.decode_unsigned(x_num, :big))
    alpha = FieldElement.pow(x, 3) +++ Secp256Field.new(@b)
    beta = Secp256Field.sqrt(alpha)
    p = Secp256Field.p()

    {even_beta, odd_beta} =
      if rem(beta.num, 2) == 0 do
        {beta, Secp256Field.new(p - beta.num)}
      else
        {Secp256Field.new(p - beta.num), beta}
      end

    case prefix == 2 do
      true -> Secp256Point.new(x, even_beta)
      false -> Secp256Point.new(x, odd_beta)
    end
  end

  def parse(_sec_bin), do: {:error, :invalid_sec_format}

  @doc """
  Generates a Bitcoin address from a secp256k1 point.

  ## Parameters
    - point: %Secp256Point{} (public key).
    - is_compressed: Boolean for compressed/uncompressed SEC format.
    - is_testnet: Boolean for testnet (true) or mainnet (false).

  ## Returns
    - String.t() with Base58Check-encoded address.
    - {:error, reason} if invalid.
  """
  def address(point, is_compressed, is_testnet) do
    sec =
      case is_compressed do
        true -> compressed_sec(point)
        false -> uncompressed_sec(point)
      end

    h160 = CryptoUtils.hash160(sec)

    prefix =
      if is_testnet do
        <<0x6F>>
      else
        <<0x00>>
      end

    Base58.encode_base58_checksum(prefix <> h160)
  end

  @doc """
  Generates a secp256k1 public key point from a secret key.

  ## Parameters
    - secret_key: Integer or %PrivateKey{}.

  ## Returns
    - %Secp256Point{} on success.
    - {:error, reason} if invalid.
  """
  def from_secret_key(secret_key) when is_integer(secret_key) and secret_key > 0 do
    g = get_g()
    mul(g, secret_key)
  end

  def from_secret_key(%PrivateKey{secret: secret}) do
    g = get_g()
    mul(g, secret)
  end

  def from_secret_key(_secret_key), do: {:error, :invalid_secret}
end
