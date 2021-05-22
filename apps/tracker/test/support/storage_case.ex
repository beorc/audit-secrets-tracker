defmodule Tracker.StorageCase do
  use ExUnit.CaseTemplate

  setup context do
    Ecto.Adapters.SQL.Sandbox.checkout(Tracker.repo())

    unless context[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Tracker.repo(), {:shared, self()})
    end
  end
end
