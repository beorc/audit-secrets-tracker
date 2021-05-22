defmodule TrackerTest do
  use Tracker.StorageCase
  doctest Tracker
  alias Tracker

  test "creates task" do
    attrs = %{id: "1", name: "test", expire_at: ~N[2018-05-25 00:00:00.000000]}
    assert {:ok, task1} = Tracker.claim_task(attrs)
    task2 = Tracker.find_task_by(id: attrs.id, name: attrs.name)
    assert task1 == task2
  end

  test "updates task" do
    attrs = %{id: "1", name: "test", expire_at: ~N[2018-05-25 00:00:00.000000]}
    assert {:ok, _} = Tracker.claim_task(attrs)
    assert {:ok, _} = Tracker.claim_task(attrs |> Map.put(:expire_at, nil))
    task = Tracker.find_task_by(id: attrs.id, name: attrs.name)
    assert task.expire_at == nil
  end

  test "deletes task" do
    attrs = %{id: "1", name: "test", expire_at: ~N[2018-05-25 00:00:00.000000]}
    assert {:ok, _} = Tracker.claim_task(attrs)
    assert {:ok, _task} = Tracker.release_task(attrs)
    assert Tracker.find_task_by(id: attrs.id, name: attrs.name) == nil
  end

  test "guarantees task uniqueness" do
    attrs = %{
      id: "1",
      name: "test",
      expire_at:
        (System.system_time(:second) + 3600) |> DateTime.from_unix!() |> DateTime.to_naive()
    }

    assert {:ok, _task} = Tracker.claim_task(attrs)
    assert {:error, :claim_failure, _task} = Tracker.claim_task(attrs |> Map.put(:expire_at, nil))

    assert {:ok, _task} =
             Tracker.claim_task(attrs |> Map.put(:name, "test1") |> Map.put(:expire_at, nil))
  end
end
