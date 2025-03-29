require Logger
import CustomOperators

defmodule Secp256Point do
  @enforce_keys [:x, :y, :a, :b]
  defstruct [:x, :y, :a, :b]
  @n 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141
  @g_x 0x79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798
  @g_y 0x483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8
  @a 0
  @b 7

  def n do
    @n
  end

  def new(x, y) when is_integer(x) and is_integer(y) do
    a = Secp256Field.new(@a)
    b = Secp256Field.new(@b)
    Point.new(Secp256Field.new(x), Secp256Field.new(y), a, b)
  end

  def get_g() do
    new(@g_x, @g_y)
  end

  def new(x, y, a, b) do
    a = Secp256Field.new(a)
    b = Secp256Field.new(b)
    Point.new(x, y, a, b)
  end

  # We can mod by n because nG = 0.
  # That is, every n times we cycle back to zero or the point at infinity.
  def mul(point, coefficient) do
    coefficient = rem(coefficient, @n)
    Point.mul(point, coefficient)
  end

  def verify(point, z, sig) do
    #    s_inv = pow(sig.s, N - 2, N)  1
    #    u = z * s_inv % N  2
    #    v = sig.r * s_inv % N  3
    #    total = u * G + v * self  4
    #    return total.x.num == sig.r  5
    # s_inv (1/s) is calculated using Fermat’ little theorem on the order of the group,
    # n, which is prime.
    s_inv = MathUtils.powmod(sig.s, @n - 2, @n)
    # u = z/s. Note that we can mod by n as that’s the order of the group.
    u = rem(z * s_inv, @n)
    # v = r/s. Note that we can mod by n as that’s the order of the group.
    v = rem(sig.r * s_inv, @n)
    g = get_g()
    #    uG + vP should be R.
    total = Point.add(mul(g, u), mul(point, v))
    total.x.num == sig.r
  end

  def uncompressed_sec(%{
        x: %FieldElement{num: num_x},
        y: %FieldElement{num: num_y}
      }) do
    <<4>> <>
      <<num_x::unsigned-big-integer-size(256)>> <>
      <<num_y::unsigned-big-integer-size(256)>>
  end

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

  # case for uncompressed
  def parse(sec_bin = <<4, _rem::binary>>) do
    <<_prefix, num_bytes::binary-size(32), num_bytes_rest::binary>> = sec_bin

    new(
      :binary.decode_unsigned(num_bytes, :big),
      :binary.decode_unsigned(num_bytes_rest, :big)
    )
  end

  # case 2 or 3 (is_even or not)
  def parse(<<is_even, x_num::binary>>) do
    x = Secp256Field.new(x_num)
    alpha = FieldElement.pow(x, 3) +++ Secp256Field.new(@b)
    beta = Secp256Field.sqrt(alpha)
    p = Secp256Field.p()

    {even_beta, odd_beta} =
      if rem(beta.num, 2) == 0 do
        {beta, Secp256Field.new(p - beta.num)}
      else
        {Secp256Field.new(p - beta.num), beta}
      end

    case is_even == 2 do
      true -> Secp256Point.new(x, even_beta)
      false -> Secp256Point.new(x, odd_beta)
    end
  end

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
end
