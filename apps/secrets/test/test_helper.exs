database = Secrets.ensure_config![:postgresql][:dummy]

{:ok, pid} = Secrets.Postgresql.connect(database.connection)

try do
  {:ok, _, _} = Secrets.Postgresql.query(pid, "DROP DATABASE IF EXISTS dummy;")
  {:ok, _, _} = Secrets.Postgresql.query(pid, "CREATE DATABASE dummy;")
  case Secrets.Postgresql.query(pid, "SELECT 1 FROM pg_roles WHERE rolname='dummy_app';") do
    {:ok, _, [{"1"}]} ->
      :user_already_exists
    _ ->
      {:ok, _, _} = Secrets.Postgresql.query(pid, "CREATE USER dummy_app;")
  end
after
  :ok = Secrets.Postgresql.close(pid)
end

ExUnit.start()
