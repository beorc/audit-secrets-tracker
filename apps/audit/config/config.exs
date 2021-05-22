use Mix.Config

config :sentry,
  environment_name: System.get_env("RELEASE_LEVEL") || Mix.env() |> Atom.to_string(),
  included_environments: ~w(prod staging),
  enable_source_code_context: true,
  root_source_code_path: File.cwd!(),
  use_error_logger: true,
  tags: %{
    release_level: Mix.env()
  }

config :audit, ecto_repos: [Audit.Repo]
