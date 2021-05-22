defmodule Tracker.Repo.Migrations.CreateTasks do
  use Ecto.Migration

  def change do
    create table(:tasks, primary_key: false) do
      add(:id, :string, null: false, primary_key: true)
      add(:name, :string, null: false, primary_key: true)
      add(:expire_at, :naive_datetime)

      timestamps()
    end
  end
end
