require Logger
import CustomOperators

defmodule SignatureTest do
  use ExUnit.Case
  doctest Signature

  test "secret message signature" do
    e = 12345
    z = MathUtils.hash_to_int(~c"Programming Bitcoin!")
    k = 1_234_567_890
    g = Secp256Point.get_g()
    n = Secp256Point.n()
    r = Secp256Point.mul(g, k).x.num
    k_inv = MathUtils.powmod(k, n - 2, n)
    s = rem((z + r * e) * k_inv, n)
    point = Secp256Point.mul(g, e)
    #    Logger.debug("x #{inspect(point.x)}")
    #    Logger.debug("y #{inspect(point.y)}")
    #    Logger.debug("z #{inspect(Integer.to_string(z, 16))}")
    #    Logger.debug("r #{inspect(Integer.to_string(r, 16))}")
    assert Integer.to_string(z, 16) ==
             "969F6056AA26F7D2795FD013FE88868D09C9F6AED96965016E1936AE47060D48"
  end
end
