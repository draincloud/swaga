defmodule Sdk.RpcClientTest do
  require Logger
  use ExUnit.Case
  require IEx
  alias Sdk.RpcClient

  test "url is not nil" do
    %{url: url} = RpcClient.new()
    assert url != nil
  end

  test "get raw transaction " do
    rpc = RpcClient.new()
    tx_id = "eb98b02392caa172fd1a2e4e91c8a581cd333e3e39fe9a9969afa64ab5c31673"

    tx_result =
      case RpcClient.get_raw_transaction(rpc, tx_id) do
        {:ok, tx} ->
          Map.get(tx, "result") |> Map.get("hex")

        _ ->
          {:error}
      end

    assert "0200000000010144fe8feb6464f806f12d39e7acbb43564d7af87d72dea78fef80eed30e407b310100000000fdffffff02feb9af0000000000160014a34874fcb2e92e33014383b842456b486fb3acfb102700000000000016001449a548c3bc6fd00c1e6f9d9c0080f10219f7342202473044022000b67441ebbbaab8172499e792d28bb8e535e6afa0f70764c1060e57f5c75525022045b86c1c98a75948960215cd5221c0db8871f8d2dce58b5999de8ade15d15403012102857892c09c438ebfa4d13cecb5fd2fb3956a32f173ce4e8a22c92126cd2e2e90b6694400" ==
             tx_result
  end
end
