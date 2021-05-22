defmodule Secrets.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  import Supervisor.Spec, warn: false

  def start(_type, _args) do
    Task.start(&Secrets.ensure_config!/0)

    children = [
      Supervisor.child_spec(
        {SharedModules.Rpc.HealthChecker, SharedModules.Config.nats_connection_name()},
        id: "rpc-health-checker"
      )
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Secrets.Supervisor]
    Supervisor.start_link(children ++ gnat_supervisors(), opts)
  end

  defp gnat_supervisors do
    if System.get_env("DISABLE_MQ") == "true" do
      []
    else
      node_id = SharedModules.Config.node_id()

      consumer_settings = %{
        connection_name: SharedModules.Config.nats_connection_name(),
        consuming_function: {Secrets.Rpc.Consumer, :process_message},
        subscription_topics: [
          %{topic: "rpc.Secrets.Actions", queue_group: "rpc.Secrets.Actions"},
          %{
            topic: "rpc.Secrets.#{node_id}.*",
            queue_group: "rpc.Secrets.#{node_id}"
          }
        ]
      }

      workers =
        [Supervisor.child_spec({Gnat.ConsumerSupervisor, consumer_settings}, shutdown: 30_000)]

      if Process.whereis(SharedModules.Config.nats_connection_name()) do
        workers
      else
        [Supervisor.child_spec({Gnat.ConnectionSupervisor, SharedModules.Config.nats_config()}, []) | workers]
      end
    end
  end
end
