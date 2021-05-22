defmodule Audit.Tasks do
  @truncate_query """
  TRUNCATE TABLE
  audit_log,
  audit_log_transactions,
  operations,
  audit_operations,
  audit_transactions,
  audit_records
  RESTART IDENTITY;
  """

  @drop_query """
  DROP TABLE IF EXISTS
  audit_log,
  audit_log_transactions,
  operations,
  audit_operations,
  audit_transactions,
  audit_records
  CASCADE;
  """

  def migrate do
    SharedModules.DB.Ops.migrate(:audit)

    :init.stop()
  end

  def drop do
    Application.load(:audit)
    Application.ensure_all_started(:postgrex)
    Application.ensure_all_started(:ssl)

    {:ok, pid} =
      Application.get_env(:audit, Audit.Repo)
      |> Keyword.put(:pool_size, 2)
      |> Postgrex.start_link()

    Postgrex.query!(pid, @drop_query, [])
    Postgrex.query!(pid, "TRUNCATE TABLE schema_migrations RESTART IDENTITY;", [])
  end

  def truncate do
    Application.load(:audit)
    Application.ensure_all_started(:postgrex)

    {:ok, pid} =
      Application.get_env(:audit, Audit.Repo)
      |> Keyword.put(:pool_size, 2)
      |> Postgrex.start_link()

    Postgrex.query!(pid, @truncate_query, [])
  end
end
