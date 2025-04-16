defmodule Swaga.MixProject do
  use Mix.Project

  def project do
    [
      app: :swaga,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :mnesia],
      mod: {Swaga, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:poison, "~> 6.0"},
      {:plug, "~> 1.7"},
      {:cowboy, "~> 2.13"},
      {:plug_cowboy, "~> 2.0"}
    ]
  end
end
