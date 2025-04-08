defmodule TxFetcher do
  @enforce_keys [
    :version,
  ]

  def get_url(false) do
    "http://testnet.programmingbitcoin.com"
  end

  def get_url(true) do
    "http://mainnet.programmingbitcoin.com"
  end

#  def fetch(tx_fetcher,tx_id, testnet\\false) do
#    response =
#  end
end