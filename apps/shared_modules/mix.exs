defmodule SharedModules.MixProject do
  use Mix.Project

  def project do
    [
      app: :shared_modules,
      version: "0.1.0",
      build_path: "../../_build",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:httpoison, "~> 1.6"},
      {:ecto, "~> 3.0"},
      {:ecto_sql, "~> 3.0"},
      {:elixir_uuid, "~> 1.2"},
      {:timex, "~> 3.6"},
      {:jason, "~> 1.1"},
      {:gnat, "~> 1.2"},
      {:absinthe, "~> 1.5"}
    ]
  end
end
