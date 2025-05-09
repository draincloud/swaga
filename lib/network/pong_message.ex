defmodule PongMessage do
  @enforce_keys [:nonce]
  defstruct nonce: 0

  def command() do
    "pong"
  end

  def new(nonce) do
    %PongMessage{nonce: nonce}
  end

  def parse(message) when is_binary(message) do
    <<eight_bytes::binary-size(8), _::binary>> = message
    %PongMessage{nonce: eight_bytes}
  end

  def serialize(%PongMessage{nonce: nonce}) do
    nonce
  end
end
