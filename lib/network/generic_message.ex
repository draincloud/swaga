defmodule GenericMessage do
  @behaviour Message
  @enforce_keys [:command, :payload]
  defstruct [:command, :payload]

  def new(command, payload) do
    %GenericMessage{command: command, payload: payload}
  end

  def command(%GenericMessage{command: command}), do: command

  def serialize(%GenericMessage{payload: payload}) do
    payload
  end
end
