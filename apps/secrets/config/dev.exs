import Config

config =
  with {:ok, config} <- File.read("dev.json") do
    config
  else
    _ -> "{}"
  end

config :secrets,
  config: config

config :audit, Audit.Repo,
  database: "audit_dev",
  hostname: System.get_env("PG_HOSTNAME", "postgres"),
  username: "postgres",
  password: "postgres",
  pool: Ecto.Adapters.SQL.Sandbox
