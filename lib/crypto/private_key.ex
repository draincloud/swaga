defmodule PrivateKey do
  @moduledoc """
  Represents a Bitcoin private key for the secp256k1 elliptic curve.
  Provides functions for creating private keys, generating ECDSA signatures,
  extracting public keys, and encoding in Wallet Import Format (WIF).
  """
  @type t :: %__MODULE__{
          secret: pos_integer(),
          point: Point.t()
        }

  @enforce_keys [:secret, :point]
  defstruct [:secret, :point]

  @doc """
  Creates a new private key for the secp256k1 curve.

  ## Parameters
    - secret: Integer private key (1 ≤ secret < n, where n is the curve order).

  ## Returns
    - %PrivateKey{} if valid.
    - {:error, reason} if invalid.
  """
  def new(secret) when is_integer(secret) and secret > 0 do
    n = Secp256Point.n()

    if secret >= n do
      {:error, :secret_out_of_range}
    else
      g = Secp256Point.get_g()
      %PrivateKey{secret: secret, point: Point.mul(g, secret)}
    end
  end

  def new(_secret), do: {:error, :invalid_secret}

  @doc """
  Generates an ECDSA signature for a message hash using the private key.

  ## Parameters
    - private_key: %PrivateKey{} for secp256k1.
    - z: 256-bit integer (typically SHA-256 hash of the message).

  ## Returns
    - %Signature{} if valid.
    - {:error, reason} if invalid.
  """
  def sign(%PrivateKey{secret: secret, point: _point}, z) when is_integer(z) and z >= 0 do
    n = Secp256Point.n()
    g = Secp256Point.get_g()
    # Replace with deterministic_k RFC 6979
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

  @doc """
  Extracts the public key point from a private key.

  ## Returns
    - %Point{} representing the public key.
  """
  def extract_point(%PrivateKey{point: point}) when is_struct(point, Point), do: point
  def extract_point(_key), do: {:error, :invalid_private_key}

  @doc """
  Encodes the private key in Wallet Import Format (WIF).

  ## Parameters
    - private_key: %PrivateKey{} for secp256k1.
    - compressed: Boolean indicating if the public key is compressed.
    - is_testnet: Boolean indicating testnet (true) or mainnet (false).

  ## Returns
    - {String.t()} with the WIF-encoded key.
    - {:error, reason} if invalid.
  """
  def wif(%PrivateKey{secret: secret}, compressed, is_testnet)
      when is_integer(secret) and is_boolean(compressed) and is_boolean(is_testnet) do
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
