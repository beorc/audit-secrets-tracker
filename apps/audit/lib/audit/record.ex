defmodule Audit.Record do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "audit_records" do
    belongs_to(:parent, Audit.Record, type: :binary_id, foreign_key: :parent_id)
    belongs_to(:operation, Audit.Operation, type: :binary_id, foreign_key: :audit_operation_id)
    has_many(:transactions, Audit.Transaction, foreign_key: :audit_record_id)

    field(:name, :string)
    field(:input, :map)
    field(:outcome, :map)

    timestamps()
  end

  def changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, [
      :name,
      :input,
      :outcome,
      :parent_id,
      :audit_operation_id
    ])
    |> validate_required([:name, :input, :outcome])
  end
end
