defmodule Assex.MixProject do
  use Mix.Project

  def project do
    [
      app: :assex,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Assex.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:memento, "~> 0.3.2"},
      {:map_diff, "~> 1.3"},
      {:luerl, "~> 1.0"},
      {:phoenix_pubsub, "~> 2.0"},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.14", only: :test},
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false},
      {:typed_struct, "~> 0.3.0"},
      {:jason, "~> 1.3"}
    ]
  end
end
