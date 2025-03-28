require Logger

defmodule PrivateKey do
  @enforce_keys [:secret, :point]
  defstruct [:secret, :point]

  def new(secret) when is_integer(secret) do
    g = Secp256Point.get_g()
    %PrivateKey{secret: secret, point: Point.mul(g, secret)}
  end

  def display(pk) do
    Logger.debug("Private key #{inspect(pk)}")
  end

  def sign(%PrivateKey{secret: secret, point: _point}, z) do
    n = Secp256Point.n()
    g = Secp256Point.get_g()
    k = :rand.uniform(n)
    r = Point.mul(g, k).x.num
    k_inv = MathUtils.powmod(k, n - 2, n)
    s = rem((z + r * secret) * k_inv, n)

    s =
      if s > n / 2 do
        n - s
      else
        s
      end

    %Signature{r: r, s: s}
  end
end
