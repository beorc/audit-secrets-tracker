defmodule SharedModules.Config do
  def profiles do
    %{
      tls: %{
        # (required) the registered name you want to give the Gnat connection
        name: nats_connection_name(),
        # number of milliseconds to wait between consecutive reconnect attempts
        backoff_period: 2_000,
        connection_settings: %{
          port: nats_port(),
          tls: true,
          ssl_opts: [
            certfile: System.get_env("NATS_CERTPATH", "/etc/nats/tls/tls.crt"),
            keyfile: System.get_env("NATS_KEYPATH", "/etc/nats/tls/tls.key")
          ]
        }
      },
      simple: %{
        # (required) the registered named you want to give the Gnat connection
        name: nats_connection_name(),
        # number of milliseconds to wait between consecutive reconnect attempts
        backoff_period: 2_000,
        connection_settings: [
          %{host: System.get_env("NATS_HOSTNAME", "nats"), port: nats_port()}
        ]
      }
    }
  end

  def node_id,
    do: System.fetch_env!("HOSTNAME")

  @spec nats_port :: integer()
  def nats_port,
    do: System.get_env("NATS_PORT", "4222") |> String.to_integer()

  @spec nats_profile(atom()) :: Keyword.t()
  def nats_profile(profile_name),
    do: Map.fetch!(profiles(), profile_name)

  def current_nats_profile,
    do: System.get_env("NATS_PROFILE", "simple") |> String.to_existing_atom()

  @spec nats_connection_settings :: map()
  def nats_connection_settings,
    do: nats_connection_settings(current_nats_profile())

  @spec nats_connection_settings(atom()) :: map()
  def nats_connection_settings(profile_name),
    do: populate_host_field(nats_profile(profile_name)[:connection_settings])

  def nats_connection_name,
    do: :mq

  @spec nats_config :: map()
  def nats_config,
    do: nats_config(current_nats_profile())

  @spec nats_config(atom()) :: map()
  def nats_config(profile_name) do
    profile = nats_profile(profile_name)
    connection_settings = Map.fetch!(profile, :connection_settings)

    Map.put(profile, :connection_settings, populate_host_field(connection_settings))
  end

  @spec nats_hosts(String.t()) :: list()
  def nats_hosts(host) do
    case :inet_res.getbyname(String.to_charlist(host), :srv) do
      {:error, :nxdomain} ->
        List.wrap(host)
      {:ok, result} ->
        result
        |> elem(5)
        |> Enum.filter(&elem(&1, 2) == 4222)
        |> Enum.map(&elem(&1, 3))
    end
  end

  def populate_host_field(settings) when is_list(settings),
    do: Enum.map(settings, &populate_host_field/1)

  def populate_host_field(settings) when is_map(settings) do
    case System.fetch_env!("NATS_HOSTNAME") |> nats_hosts() do
      [host] ->
        Map.put_new(settings, :host, host)
      hosts when is_list(hosts) ->
        Enum.map(hosts, &Map.put_new(settings, :host, &1))
    end
  end

  # Backward compatibility

  def mq_config(app) when is_atom(app) do
    config =
      Application.get_env(app, :mq) ||
      raise ArgumentError, "NATS configuration not specified in environment"

    config = Enum.into(config, %{})
    node_id = System.get_env("HOSTNAME") || "Default"
    connection_settings = connection_settings(config)

    config
    |> Map.put(:connection_settings, connection_settings)
    |> Map.put_new(:node_id, node_id)
  end

  defp connection_settings(%{connection_settings: settings}) when is_list(settings),
    do: settings

  defp connection_settings(%{connection_settings: settings}) when is_map(settings),
    do: populate_host_field(settings)

  defp connection_settings(_config),
    do: connection_settings(%{connection_settings: %{port: 4222}})
end
