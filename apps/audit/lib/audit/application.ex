defmodule Audit.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    SharedModules.DB.Ops.migrate(:audit)

    import Supervisor.Spec, warn: false

    # List all child processes to be supervised
    children = [
      supervisor(Audit.Repo, [])
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Audit.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
