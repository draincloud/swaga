require Logger
defmodule Swaga do
  @moduledoc """
  Documentation for `Swaga`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Swaga.hello()
      :world

  """

  def start(type, args) do
    Logger.debug("Start")
  end

  def hello do
    :world
  end
end
