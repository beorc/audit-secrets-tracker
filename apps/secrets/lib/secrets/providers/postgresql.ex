defmodule Secrets.Postgresql do
  require Logger

  @password_length_bytes 64
  @provisioner "provisioner"
  @provision [
    "GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO $1 WITH GRANT OPTION;",
    "GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO $1 WITH GRANT OPTION;"
  ]

  def connect(config) do
    config
    |> database_connection_config()
    |> SharedModules.Utils.map_values_to_charlist()
    |> :epgsql.connect()
  end

  def query(pid, query),
    do: :epgsql.squery(pid, query)

  def close(pid),
    do: :epgsql.close(pid)

  def apply_config(config) do
    Enum.map(config[:postgresql] || [], fn({database_name, database_config}) ->
      Logger.info(fn -> "Ensuring PostgreSQL roles for database #{database_name}..." end)

      create_users(database_name, database_config)
    end)
  end

  def generate_password(length \\ @password_length_bytes),
    do: Base.url_encode64(:crypto.strong_rand_bytes(length), padding: false)

  def rotate_credentials(args, config) do
    with {:database, database} when is_map(database) <- {:database, config[String.to_atom(args.database)]},
        username <- String.to_atom(args.username),
        {:user, {_username, %{connection: user_connection}}} <- {:user, Enum.find(database.users, &(elem(&1, 0) == username))},
        password <- Secrets.Postgresql.generate_password() do
          {:ok, pid} = Secrets.Postgresql.connect(database.connection)

          try do
            {:ok, _, _} = Secrets.Postgresql.query(pid, "ALTER USER #{username} WITH PASSWORD '#{password}';")
          after
            :ok = Secrets.Postgresql.close(pid)
          end

          connection_config =
            user_connection
            |> Map.merge(database.connection)
            |> Map.put(:database, SharedModules.Utils.to_string(args.database))
            |> Map.put(:username, args.username)
            |> Map.put(:password, password)

          topic =
            SharedModules.DB.Config.topic([provider: args.provider, database: args.database, username: args.username])

          :ok = Gnat.pub(SharedModules.Config.nats_connection_name(), topic, Jason.encode!(connection_config))

          Logger.info(fn -> "[#{args.database}] Password rotation succeeded" end)
    else
      {:database, nil} ->
        SharedModules.Graph.Reply.not_found("Configuration for database #{args.database} not found")
      {:user, nil} ->
        SharedModules.Graph.Reply.not_found("Configuration for username #{args.username} not found")
    end
  end

  defp database_connection_config(config) do
    config =
      case config[:ssl] do
        nil ->
          config
        value ->
          Map.put(config, :ssl, SharedModules.Utils.to_atom(value))
      end

    config =
      case config[:cacertfile] do
        nil ->
          config
        value ->
          config
          |> Map.delete(:cacertfile)
          |> Map.put(:ssl_opts, [cacertfile: SharedModules.Utils.to_charlist(value)])
      end

    case config[:password] do
      nil ->
        token = ExAws.RDS.generate_db_auth_token(config.host, config.username, config.port)

        Map.put(config, :password, token)
      _ ->
        config
    end
  end

  def create_users(database_name, database_config) do
    database_name = SharedModules.Utils.to_string(database_name)

    with {:ok, pid} <- connect(database_config.connection) do
      try do
        result =
          Enum.map(database_config[:users], fn({username, _user_config}) ->
            create_user(pid, username)
          end)

        password =
          case query(pid, "SELECT 1 FROM pg_roles WHERE rolname='#{@provisioner}';") do
            {:ok, _, [{"1"}]} ->
              password = generate_password()
              {:ok, _, _} = query(pid, "ALTER USER #{@provisioner} WITH PASSWORD '#{password}';")
              password
            _ ->
              {:ok, _, password} = create_user(pid, @provisioner)
              password
          end

        provisioner_config =
          database_config
          |> Map.put(:connection, Map.put(database_config.connection, :database, database_name))
          |> Map.put(:users, %{String.to_atom(@provisioner) => %{provision: @provision}})

        :ok = provision_roles(database_name, provisioner_config)

        connection_config =
          database_config.connection
          |> Map.put(:database, database_name)
          |> Map.put(:username, @provisioner)
          |> Map.put(:password, password)

        :ok = provision_roles(database_name, Map.put(database_config, :connection, connection_config))

        {:ok, result}
      rescue
        e ->
          Logger.error(fn -> "Error on roles provisioning: #{inspect(e)}" end)
          {:error, e}
      after
        :ok = close(pid)
      end
    else
      result ->
        Logger.error(fn -> "Could not connect to database #{database_name}" end)
        {:error, result}
    end
  end

  defp create_user(pid, username) do
    try do
      password = generate_password()
      username = SharedModules.Utils.to_string(username)

      Logger.info(fn -> "Creating user #{username}..." end)

      case query(pid, "CREATE USER #{username} WITH PASSWORD '#{password}';") do
        {:ok, _, _} ->
          Logger.info(fn -> "User #{username} created" end)
        {:error, {:error, :error, "42710", :duplicate_object, _, _}} ->
          Logger.info(fn -> "User #{username} already exists" end)
      end

      {:ok, username, password}
    rescue
      e ->
        Logger.error(fn -> "Error on create user #{username}: #{inspect(e)}" end)
        {:error, username, e}
    end
  end

  defp provision_roles(database_name, database_config) do
    database_name = SharedModules.Utils.to_string(database_name)

    Logger.info(fn -> "Provisioning roles for database #{database_name}..." end)

    try do
      with {:ok, pid} <- connect(database_config.connection) do
        try do
          Enum.map(database_config[:users], fn({username, %{provision: queries}}) ->
            username = Atom.to_string(username)

            Enum.map(queries, fn query ->
              query =
                query
                |> String.replace("$1", username)
                |> String.replace("$2", database_name)

              Logger.info(query)

              try do
                {:ok, _, _} = query(pid, query)
              rescue
                e ->
                  Logger.error(fn -> "Error on provisioning #{query}: #{inspect(e)}" end)
                  {:error, e}
              end
            end)
          end)
        after
          :ok = close(pid)
        else
          _ ->
            :ok
        end
      else
        e ->
          Logger.error(fn -> "Could not connect to database #{database_name}" end)
          {:error, e}
      end
    rescue
      e ->
        Logger.error(fn -> "Could not connect to database #{database_name}: #{inspect(e)}" end)
        {:error, e}
    end
  end
end
