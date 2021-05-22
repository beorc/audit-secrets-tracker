defmodule Audit.Operation do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "audit_operations" do
    has_many(:records, Audit.Record, foreign_key: :audit_operation_id)
    has_many(:transactions, Audit.Transaction, foreign_key: :audit_operation_id)

    field(:name, :string)
    field(:context, :map)

    field(:status, :integer)
    field(:response, :map)
    field(:error, :string)
    field(:exception, :string)
    field(:trace_id, :integer)

    timestamps()
  end

  @required_attrs ~w(name context)a
  @optional_attrs ~w(status response trace_id error exception)a

  def changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, @required_attrs ++ @optional_attrs)
    |> validate_required(@required_attrs)
  end

  def update_changeset(operation, attrs) do
    operation
    |> cast(attrs, ~w(status response error exception)a)
    |> validate_required(@required_attrs)
  end
end
