defmodule SharedModules.DB.Config do
  @postgresql "postgresql"
  @succeeded "Succeeded"
  @required "required"

  def init(_type, config) do
    if config[:password] do
      {:ok, config}
    else
      rotate_credentials(Keyword.put_new(config, :provider, @postgresql))
    end
  end

  def postgrex_config(config) when is_map(config),
    do: Enum.map(config, &{elem(&1, 0), elem(&1, 1)})

  def postgrex_config(config) when is_list(config),
    do: config

  @spec topic(Keyword.t()) :: String.t()
  def topic(config),
    do: Enum.join([Keyword.fetch!(config, :provider), Keyword.fetch!(config, :database), Keyword.fetch!(config, :username)], ".")

  @spec rotate_credentials(Keyword.t()) :: {:ok, String.t()} | {:error, String.t()}
  def rotate_credentials(config) do
    topic = topic(config)
    connection_settings = List.first(SharedModules.Config.nats_connection_settings())
    {:ok, pid} = Gnat.start_link(connection_settings)
    {:ok, sid} = Gnat.sub(pid, self(), topic)

    try do
      args = %{provider: @postgresql, database: Keyword.fetch!(config, :database), username: Keyword.fetch!(config, :username)}

      with {:ok, @succeeded} <- SharedModules.Rpc.Secrets.rotate_credentials(args, connection: pid) do
        connection_config =
          receive do
            {:msg, %{sid: ^sid, topic: ^topic, body: body}} ->
              body
          end
          |> Jason.decode!(keys: :atoms)
          |> SharedModules.DB.Config.database_connection_config()

        {:ok, Keyword.merge(postgrex_config(config), postgrex_config(connection_config))}
      else
        {:error, [%{message: message, details: details}]} ->
          {:error, message, details}
        {:error, [%{message: message}]} ->
          {:error, message}
      end
    after
      :ok = Gnat.unsub(pid, sid)
      :ok = Gnat.stop(pid)
    end
  end

  def database_connection_config(config) do
    config =
      case config[:host] do
        nil ->
          config
        host when is_binary(host) ->
          config
          |> Map.delete(:host)
          |> Map.put(:hostname, host)
      end

    config =
      case config[:ssl] do
        @required ->
          Map.put(config, :ssl, true)
        value when is_atom(value) ->
          config
        value when is_binary(value) ->
          Map.put(config, :ssl, SharedModules.Utils.to_atom(value))
      end

    case config[:cacertfile] do
      nil ->
        config
      value when is_binary(value) ->
        config
        |> Map.delete(:cacertfile)
        |> Map.put(:ssl_opts, [cacertfile: value])
    end
  end

  @doc """
  Normalizes the application configuration.
  """
  def parse(config) do
    {url, config} = Keyword.pop(config, :url)

    config
    |> Keyword.merge(parse_url(url || ""))
    |> Keyword.merge(pool: DBConnection.Poolboy)
  end

  @doc """
  Converts a database url into a Keyword list
  """
  def parse_url(""), do: []

  def parse_url({:system, env}) when is_binary(env) do
    parse_url(System.get_env(env) || "")
  end

  def parse_url(url) do
    info = url |> URI.decode() |> URI.parse()

    if is_nil(info.host) do
      raise ArgumentError, message: "host is not present"
    end

    if is_nil(info.path) or not (info.path =~ ~r"^/([^/])+$") do
      raise ArgumentError, message: "path should be a database name"
    end

    destructure [username, password], info.userinfo && String.split(info.userinfo, ":")
    "/" <> database = info.path

    opts = [
      username: username,
      password: password,
      database: database,
      hostname: info.host,
      port: info.port
    ]

    Enum.reject(opts, fn {_k, v} -> is_nil(v) end)
  end
end
