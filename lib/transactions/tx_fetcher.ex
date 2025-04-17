require Logger
import Req

defmodule TxFetcher do
  #  @enforce_keys [
  #    :version
  #  ]

  def get_url(true) do
    "http://testnet.programmingbitcoin.com"
  end

  def get_url(false) do
    "https://blockstream.info/api"
  end

  def fetch(tx_id, testnet) do
    url = get_url(testnet)
    url = url <> "/tx/" <> tx_id <> "/hex"
    response = Req.get!(url)
    decoded = Base.decode16!(response.body, case: :lower)
    decoded_list = :binary.bin_to_list(decoded)
    fifth_elem = Enum.at(decoded_list, 4)
    parse_block_stream_tx(fifth_elem, :binary.list_to_bin(decoded_list))
  end

  def parse_block_stream_tx(0, raw) do
    <<prefix4::binary-size(4), _::binary-size(2), rest::binary>> = raw
    concat_raw = prefix4 <> rest
    #    Logger.debug("bsize #{inspect(byte_size(concat_raw))}")
    <<_::binary-size(byte_size(raw) - 4), last4::binary-size(4)>> = raw
    tx = Tx.parse(concat_raw)
    updated_tx = Map.put(tx, :locktime, MathUtils.little_endian_to_int(last4))
  end

  def parse_block_stream_tx(_, raw) do
    tx = Tx.parse(raw)
  end

  #  def fetch(tx_fetcher,tx_id, testnet\\false) do
  #    response =
  #  end
end
