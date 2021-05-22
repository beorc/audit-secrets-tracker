defmodule Audit.StorageCase do
  use ExUnit.CaseTemplate

  setup context do
    Ecto.Adapters.SQL.Sandbox.checkout(Audit.Repo, sandbox: true)

    unless context[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Audit.Repo, {:shared, self()})
    end

    context
  end
end
