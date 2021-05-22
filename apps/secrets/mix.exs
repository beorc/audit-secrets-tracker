defmodule Secrets.MixProject do
  use Mix.Project

  def project do
    [
      app: :secrets,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Secrets.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:gnat, "~> 1.2"},
      {:epgsql, "~> 4.5"},
      {:jason, "~> 1.1"},
      {:absinthe, "~> 1.5"},
      {:ex_aws, "~> 2.0"},
      {:ex_aws_secretsmanager, "~> 2.0"},
      {:ex_aws_sts, "~> 2.0"},
      {:ex_aws_rds, "~> 2.0"},
      {:sweet_xml, "~> 0.6"},
      {:configparser_ex, "~> 4.0"},
      {:audit, in_umbrella: true},
      {:shared_modules, in_umbrella: true, runtime: false}
    ]
  end
end
