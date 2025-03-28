require Logger

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
end
