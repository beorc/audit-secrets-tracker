defmodule Tracker.MixProject do
  use Mix.Project

  def project do
    [
      app: :tracker,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.9",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test) do
    [
      "lib",
      "test/support"
    ]
  end

  defp elixirc_paths(_) do
    [
      "lib"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Tracker.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ecto_sql, "~> 3.0"},
      {:postgrex, "~> 0.14"},
      {:jason, "~> 1.1"},
      {:tesla, "~> 1.3"},
      {:hackney, "~> 1.15"},
      {:shared_modules, in_umbrella: true, runtime: false}
    ]
  end
end
