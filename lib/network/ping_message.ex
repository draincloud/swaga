defmodule PingMessage do
  @enforce_keys [:nonce]
  defstruct nonce: 0

  def command() do
    "ping"
  end

  def new(nonce) do
    %PingMessage{nonce: nonce}
  end

  def parse(message) when is_binary(message) do
    <<eight_bytes::binary-size(8), _::binary>> = message
    %PingMessage{nonce: eight_bytes}
  end

  def serialize(%PingMessage{nonce: nonce}) do
    nonce
  end
end
