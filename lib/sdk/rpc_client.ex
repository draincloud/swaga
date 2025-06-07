defmodule Sdk.RpcClient do
  require IEx
  defstruct [:url, :network]

  def new(opts \\ []) do
    url = Application.get_env(:swaga, :config) |> Keyword.get(:btc_node_endpoint)
    network = Keyword.get(opts, :network, :mainnet)
    %__MODULE__{url: url, network: network}
  end

  def send_request(%__MODULE__{url: url}, json_payload) when is_binary(json_payload) do
    headers = [
      {"Content-Type", "application/json"},
      {"Accept", "application/json"}
    ]

    case HTTPoison.post(url, json_payload, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        case Poison.decode(body) do
          {:ok, decoded_body} -> {:ok, decoded_body}
          {:error, reason} -> {:error, {:json_decoding_error, reason}}
        end

      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        {:error, {:http_error, status_code, body}}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, {:httpoison_error, reason}}
    end
  end

  def build_request(method, id, params) do
    request = %{jsonrpc: "2.0", id: id, method: method, params: params}
    request |> Poison.encode()
  end

  @doc """
    # minconf - Minimum cofirmations (0 for unconfirmed, 1 for confirmed)
    # maxconf - Maximum confirmations
    # addresses - Ar array containing the single Bech32 address
    # include_unsafe - Set to true to include unconfirmed UTXOs from unknown sources
    # query_options - A map for additional filters (e.g. {minimumAmount: 0.1})
  """
  def get_utxos(%__MODULE__{} = rpc, address, params \\ []) when is_binary(address) do
    method = "listunspent"
    id = ""
    min_conf = Keyword.get(params, :minconf, 1)
    max_conf = Keyword.get(params, :maxconf, 9_999_999)
    include_unsafe = Keyword.get(params, :include_unsafe, false)

    case build_request(method, id, [min_conf, max_conf, [address], include_unsafe]) do
      {:ok, encoded} -> send_request(rpc, encoded)
      {:error, reason} -> {:error, "Could not encode json #{inspect(reason)}"}
    end
  end

  @doc """
    # txid - string
    # verbose - boolean, if false return a string, else return a json object
    # blockhash - string, optional
  """
  def get_raw_transaction(%__MODULE__{} = rpc, txid, params \\ []) when is_binary(txid) do
    method = "getrawtransaction"
    id = "swaga"
    verbose = Keyword.get(params, :verbose, true)
    blockhash = Keyword.get(params, :blockhash, nil)

    case build_request(method, id, [txid, verbose, blockhash]) do
      {:ok, encoded} -> send_request(rpc, encoded)
      {:error, reason} -> {:error, "Could not encode json #{inspect(reason)}"}
    end
  end

  @doc """
    # hexstring - This is your fully signed, serialized transaction in hexadecimal format.
    # maxfeerate - numeric, optional.
  """
  def send_raw_transaction(%__MODULE__{} = rpc, serialized_tx, params \\ [])
      when is_binary(serialized_tx) do
    method = "sendrawtransaction"
    id = "swaga"
    # Setting to 0 disable this check
    max_fee_rate = Keyword.get(params, :maxfeerate, 0)

    case build_request(method, id, [serialized_tx, max_fee_rate]) do
      {:ok, encoded} -> send_request(rpc, encoded)
      {:error, reason} -> {:error, "Could not encode json #{inspect(reason)}"}
    end
  end
end
