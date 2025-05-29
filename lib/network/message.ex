defmodule Message do
  @doc """
  Interface for message in protocol
  """
  @callback new(Keyword.t() | map()) :: struct()
  @callback serialize(struct()) :: binary()
  @callback command() :: String.t()
end
