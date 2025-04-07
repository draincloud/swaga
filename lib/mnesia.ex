defmodule Cache do
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

    case :mnesia.create_table(Services, [attributes: [
                                           :id,
                                           :service_name,
                                           :service_version
    ]]) do
      {:atomic, :ok} -> :logger.info("[#{__MODULE__}] Services table created")
      {:aborted, {:already_exists, Services}} -> :logger.info("[#{__MODULE__}] Services table alreay created")
      reason ->  raise "failed to create Services table: #{Kernel.inspect(reason)}"
    end
  end
end
