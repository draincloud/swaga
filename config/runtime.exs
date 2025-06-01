import Config
import Dotenvy

source!([
  Path.absname(".env"),
  System.get_env()
])

config :swaga, :config, btc_node_endpoint: env!("BTC_NODE_ENDPOINT", :string!)
