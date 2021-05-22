defmodule Tracker.Task do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false

  schema "tasks" do
    field :id, :string, primary_key: true
    field :name, :string, primary_key: true
    field :expire_at, :naive_datetime

    timestamps()
  end

  @required_attrs ~w(id name)a
  @optional_attrs ~w(expire_at)a

  def changeset(%__MODULE__{} = task, attrs) do
    task
    |> cast(attrs, @required_attrs ++ @optional_attrs)
    |> unique_constraint(:id, name: :tasks_pkey)
    |> validate_required(@required_attrs)
  end
end
