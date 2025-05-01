require Logger

defmodule PrivateKey do
  @enforce_keys [:secret, :point]
  defstruct [:secret, :point]

  def new(secret) when is_integer(secret) do
    g = Secp256Point.get_g()
    %PrivateKey{secret: secret, point: Point.mul(g, secret)}
  end

  #  def display(pk) do
  #    Logger.debug("Private key #{inspect(pk)}")
  #  end

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

    Logger.debug("sign #{inspect(%Signature{r: r, s: s})}")
    sig = %Signature{r: r, s: s}
  end

  def extract_point(%PrivateKey{point: point}) do
    point
  end

  def wif(%PrivateKey{secret: secret}, compressed, is_testnet) do
    secret = :binary.encode_unsigned(secret, :big)

    secret_size = bit_size(secret)

    secret =
      if secret_size < 256 do
        <<0::size(256 - secret_size)>> <> secret
      else
        secret
      end

    prefix =
      if is_testnet do
        <<0xEF>>
      else
        <<0x80>>
      end

    suffix =
      if compressed do
        <<0x01>>
      else
        <<>>
      end

    Base58.encode_base58_checksum(prefix <> secret <> suffix)
  end
end
