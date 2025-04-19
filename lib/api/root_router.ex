defmodule Swaga.Router do
  use Plug.Router

  plug(:match)
  plug(:dispatch)

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]}
    }
  end

  def start_link(_opts) do
    :logger.info("starting root router")
    Plug.Cowboy.http(__MODULE__, [])
  end

  # Healthcheck
  get "/ping" do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Poison.encode!(%{text: "PONG"}))
  end

  # Unknown route
  match _ do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(
      404,
      Poison.encode!(%{
        code: 404,
        message: "Not Found"
      })
    )
  end
end
