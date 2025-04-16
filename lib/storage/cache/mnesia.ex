defmodule Swaga.Storage.Cache do
  use GenServer

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]}
    }
  end

  def start_link(opts) do
    start(opts)
  end

  def start(opts) do
    :logger.info("[Swaga.Storage.Cache] starting swaga mnesia cache")
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_) do
    initialize_mnesia()
    {:ok, %{}}
  end

  defp initialize_mnesia() do
    case :mnesia.create_schema([node()]) do
      {:error, {_, {:already_exists, _}}} ->
        :logger.info("[#{__MODULE__}] schema already exist")
      _ ->
        :logger.info("[#{__MODULE__}] schema initialized")
    end

    case :mnesia.start() do
      :ok -> :logger.info("[#{__MODULE__}] mnesia started")
      reason -> raise "failed to start mnesia: #{Kernel.inspect(reason)}"
    end

    case :mnesia.create_table(KeyValCacheV1, [attributes: [
      :id,
      :val
    ]]) do
      {:atomic, :ok} -> :logger.info("[#{__MODULE__}] KeyValCacheV1 table created")
      {:aborted, {:already_exists, KeyValCacheV1}} -> :logger.info("[#{__MODULE__}] KeyValCacheV1 table alreay created")
      reason ->  raise "failed to create KeyValCacheV1 table: #{Kernel.inspect(reason)}"
    end
  end

  @impl true
  def handle_call({:key_val_add_call, req}, _from, state) do
    :logger.debug("handle_call call")

    
    {:reply, state}
  end

  @impl true
  def handle_cast({req, element}, state) do
    :logger.debug("handle_cast call")
    {:noreply, state}
  end
end
