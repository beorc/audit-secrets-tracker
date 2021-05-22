defmodule SharedModules.Rpc.HealthChecker do
  use GenServer
  require Logger

  @filename "alive.txt"

  def start_link(connection_name),
    do: GenServer.start_link(__MODULE__, connection_name)

  def init(connection_name) do
    Process.send_after(self(), :check, 15_000)

    {:ok, connection_name}
  end

  def handle_info(:check, connection_name) do
    with pid when is_pid(pid) <- Process.whereis(connection_name) do
      :ok = File.touch(@filename)
    end

    Process.send_after(self(), :check, 15_000)

    {:noreply, connection_name}
  end
end
