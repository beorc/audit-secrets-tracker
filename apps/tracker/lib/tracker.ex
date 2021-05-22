defmodule Tracker do
  alias Tracker.Task

  def repo,
    do: Tracker.Repo

  @spec find_task_by(list) :: Task.t() | nil
  def find_task_by(id: id, name: name) do
    repo().get_by(Task, id: id, name: name)
  end

  @spec claim_task(map) :: {:ok, Task.t()} | {:error, :claim_failure, Task.t()}
  def claim_task(%{id: id, name: name} = attrs) do
    case create_task(attrs) do
      {:ok, task} ->
        {:ok, task}

      {:error,
       %Ecto.Changeset{
         errors: [
           id: {"has already been taken", [constraint: :unique, constraint_name: "tasks_pkey"]}
         ]
       }} ->
        task = find_task_by(id: id, name: name)

        case task do
          nil ->
            {:ok, nil} # the task has been released
          task ->
            if task.expire_at && NaiveDateTime.compare(task.expire_at, NaiveDateTime.utc_now()) == :lt do
              update_task(task, expire_at: attrs[:expire_at])
            else
              {:error, :claim_failure, task}
            end
        end
    end
  end

  @spec release_task(map) :: {:ok, Task.t()} | {:ok, nil} | {:error, Ecto.Changeset.t()}
  def release_task(nil),
    do: {:ok, :nil}

  def release_task(%{id: id, name: name}) do
    find_task_by(id: id, name: name) |> delete_task()
  end

  defp create_task(attrs) do
    %Task{}
    |> Task.changeset(attrs)
    |> repo().insert()
  end

  defp update_task(task, expire_at: expire_at) do
    task
    |> Ecto.Changeset.change(expire_at: expire_at)
    |> repo().update()
  end

  defp delete_task(nil),
    do: {:ok, nil}

  defp delete_task(task) do
    repo().delete(task)
  end
end
