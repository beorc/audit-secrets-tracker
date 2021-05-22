defmodule Secrets.Rpc.ConsumerTest do
  use ExUnit.Case

  describe "rotate_credentials" do
    setup do
      SharedModules.Wait.until_bool(fn ->
        {:ok, subs} = SharedModules.Config.nats_connection_name() |> Gnat.active_subscriptions()
        subs > 2
      end)
    end

    test "should update password and publish connection config to private topic" do
      args = [provider: "postgresql", database: "dummy", username: "dummy_app"]

      {:ok, config} = SharedModules.DB.Config.rotate_credentials(args)

      assert config[:database] == Keyword.fetch!(args, :database)
      assert config[:hostname] == System.get_env("PG_HOSTNAME", "postgres")
      assert config[:port] == 5432
      assert config[:username] == Keyword.fetch!(args, :username)
      assert config[:password]
      assert config[:pool_size] == 3
    end

    test "should do nothing if database not found" do
      args = [provider: "postgresql", database: "dummy31337", username: "dummy31337_app"]

      assert {:error, "Unprocessable entity", "Configuration for database dummy31337 not found"} =
        SharedModules.DB.Config.rotate_credentials(args)
    end
  end
end
