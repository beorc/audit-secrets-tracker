defmodule Audit.Repo do
  use Ecto.Repo,
    otp_app: :audit,
    adapter: Ecto.Adapters.Postgres

  def init(type, config),
    do: SharedModules.DB.Config.init(type, config)
end
