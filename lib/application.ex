defmodule Swaga do
  use Application

  @impl true
  def start(_type, _args) do
    :logger.info("[#{__MODULE__}] starting root application")
    Supervisor.start_link(children(), opts())
  end

  defp children do
    [
      Swaga.Router,
      %{
        id: Swaga.Storage.Cache,
        start: {Swaga.Storage.Cache, :start_link, [[]]}
      }
    ]
  end

  defp opts do
    [
      strategy: :one_for_one,
      name: Swaga.Supervisor
    ]
  end
end
