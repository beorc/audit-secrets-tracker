defmodule Audit.Repo.Migrations.CreateAuditRecords do
  use Ecto.Migration

  def change do
    create table(:audit_records, primary_key: false) do
      add(:id, :uuid, primary_key: true)

      add(:name, :string, null: false)

      add(:input, :jsonb, null: false)
      add(:outcome, :jsonb, null: false)

      add(:parent_id, references(:audit_records, type: :binary_id, on_delete: :delete_all))

      add(
        :audit_operation_id,
        references(:audit_operations, type: :binary_id, on_delete: :delete_all)
      )

      timestamps()
    end
  end
end
