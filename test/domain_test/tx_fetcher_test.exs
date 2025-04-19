require Logger

defmodule TxFetcherTest do
  use ExUnit.Case

  test "should fetch correctly" do
    %{tx_ins: inputs, tx_outs: outputs} =
      TxFetcher.fetch("79df5e47c72bde48f75094cddc6c7166cf88f6caae4ffd189365e68aab5b9f8c", false)

    assert length(inputs) == 1
    assert length(outputs) == 6
  end
end
