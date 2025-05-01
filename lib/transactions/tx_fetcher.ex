require Logger

defmodule TxFetcher do
  def get_url(true) do
    "https://blockstream.info/testnet/api/"
  end

  def get_url(false) do
    "https://blockstream.info/api"
  end

  def fetch(tx_id, is_testnet \\ false) do
    response = Req.get!(get_url(is_testnet) <> "/tx/" <> tx_id <> "/hex")
    Logger.info(response)
    decoded = Base.decode16!(response.body, case: :lower)
    decoded_list = :binary.bin_to_list(decoded)
    fifth_elem = Enum.at(decoded_list, 4)
    parse_block_stream_tx(fifth_elem, :binary.list_to_bin(decoded_list))
  end

  def parse_block_stream_tx(0, raw) do
    <<prefix4::binary-size(4), _::binary-size(2), rest::binary>> = raw
    <<_::binary-size(byte_size(raw) - 4), last4::binary-size(4)>> = raw
    Map.put(Tx.parse(prefix4 <> rest), :locktime, MathUtils.little_endian_to_int(last4))
  end

  def parse_block_stream_tx(_, raw) do
    Tx.parse(raw)
  end
end
