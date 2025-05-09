# VerAckMessage is a minimal network message
defmodule VerAckMessage do
  defstruct []

  def command() do
    "verack"
  end

  def new do
    %VerAckMessage{}
  end

  def parse(_) do
    ""
  end

  def serialize(_) do
    ""
  end
end
