defmodule Audit.Repo.Migrations.CreateAuditTransactions do
  use Ecto.Migration

  def change do
    create table(:audit_transactions, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:audit_record_id, references(:audit_records, type: :binary_id, on_delete: :delete_all))

      add(
        :audit_operation_id,
        references(:audit_operations, type: :binary_id, on_delete: :delete_all)
      )

      add(:action, :string, size: 10, null: false)
      add(:subject, :string, size: 50, null: false)
      add(:context, :jsonb)
      add(:state, :jsonb)
      add(:changes, :jsonb)
      add(:outcome, :jsonb, null: false)
      add(:success, :boolean)
      add(:organization_ids, {:array, :string}, default: [], null: false)

      timestamps()
    end
  end
end
