defmodule SharedModules.DB.Ops do
  @moduledoc false
  require Logger

  @spec migrate(atom()) :: :ok
  def migrate(otp_app) do
    if System.get_env("OPS_DB_USERNAME") do
      Logger.info(fn -> "[#{otp_app}] Running migrations..." end)
      Application.load(otp_app)

      Enum.each([:ecto_sql, :postgrex, :logger, :ssl], fn app ->
        Application.ensure_all_started(app)
      end)

      app_module =
        otp_app
        |> Atom.to_string()
        |> String.capitalize()

      repo = String.to_existing_atom("Elixir." <> app_module <> ".Repo")

      {:ok, _pid} =
        Application.get_env(otp_app, repo)
        |> Keyword.put(:username, System.fetch_env!("OPS_DB_USERNAME"))
        |> Keyword.put(:password, System.get_env("OPS_DB_PASSWORD"))
        |> Keyword.put(:pool_size, 2)
        |> repo.start_link()

      path = Application.app_dir(otp_app, "priv/repo/migrations")

      Ecto.Migrator.run(repo, path, :up, all: true)

      repo.stop()
    end
  end

  @doc """
  A helper that transform changeset errors to a map of messages.
  """
  def errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Enum.reduce(opts, message, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_binary(value))
      end)
    end)
  end

  defp to_binary(value) when is_tuple(value), do: Enum.join(Tuple.to_list(value), ", ")
  defp to_binary(value), do: to_string(value)
end
