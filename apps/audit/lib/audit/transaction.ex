defmodule Audit.Transaction do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "audit_transactions" do
    belongs_to(:record, Audit.Record, type: :binary_id, foreign_key: :audit_record_id)
    belongs_to(:operation, Audit.Operation, type: :binary_id, foreign_key: :audit_operation_id)

    field(:action, :string)
    field(:subject, :string)
    field(:context, :map)
    field(:state, :map)
    field(:changes, :map)
    field(:outcome, :map)
    field(:success, :boolean)
    field(:organization_ids, {:array, :string})

    timestamps()
  end

  def changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, [
      :audit_record_id,
      :audit_operation_id,
      :organization_ids,
      :action,
      :subject,
      :context,
      :state,
      :changes,
      :outcome,
      :success
    ])
    |> validate_required([:action, :subject, :outcome, :success])
  end
end
