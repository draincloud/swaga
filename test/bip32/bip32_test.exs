require Logger

defmodule HDWalletTest do
  use ExUnit.Case

  @tag :in_progress
  test "correct creation of master key" do
    seed = "000102030405060708090a0b0c0d0e0f" |> Base.decode16!(case: :lower)

    %{chain_code: chain_code, secret: secret, depth: 0, child_number: 0} =
      ExtendedPrivateKey.new_master(seed)

    assert chain_code |> Base.encode16(case: :lower) ==
             "873dff81c02f525623fd1fe5167eac3a55a049de3d314bb42ee227ffed37d508"

    assert secret |> Base.encode16(case: :lower) ==
             "e8f32e723decf4051aefac8e2c93c9c5b214313817cdb01a1494b917c8436b35"
  end
end
