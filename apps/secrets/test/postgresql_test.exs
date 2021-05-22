defmodule Secrets.PostgresqlTest do
  use ExUnit.Case

  describe "apply_config" do
    test "creates users in database" do
      config = Secrets.ensure_config!()
      assert [ok: [{:ok, "dummy_app", _}]] = Secrets.Postgresql.apply_config(config)

      database = config[:postgresql][:dummy]
      {:ok, pid} = Secrets.Postgresql.connect(database.connection)

      try do
        assert {:ok, _, [{"1"}]} =
          Secrets.Postgresql.query(pid, "SELECT 1 FROM pg_roles WHERE rolname='dummy_app';")
        assert {:ok, _, [{"1"}]} =
          Secrets.Postgresql.query(pid, "SELECT 1 FROM pg_roles WHERE rolname='provisioner';")
      after
        :ok = Secrets.Postgresql.close(pid)
      end
    end
  end

  describe "rotate_credentials" do
    test "alters user password and published new connection config to NATS" do
      args = %{database: "dummy", provider: "postgresql", username: "dummy_app"}
      config = %{
        dummy: %{
          connection: %{
            host: System.get_env("PG_HOSTNAME", "postgres"),
            password: "postgres",
            port: 5432,
            username: "postgres"
          },
          users: %{
            dummy_app: %{
              connection: %{pool_size: 3},
              provision: ["GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO $1;"]
            }
          }
        }
      }

      assert :ok == Secrets.Postgresql.rotate_credentials(args, config)
    end
  end
end
