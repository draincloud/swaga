defmodule GenericMessage do
  @enforce_keys [:command, :payload]
  defstruct [:command, :payload]

  def command(%GenericMessage{command: command}), do: command

  def new(command, payload) do
    %GenericMessage{command: command, payload: payload}
  end

  def serialize(%GenericMessage{payload: payload}) do
    payload
  end
end
