defmodule Audit.Repo.Migrations.CreateAuditOperations do
  use Ecto.Migration

  def change do
    create table(:audit_operations, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:name, :string, null: false)
      add(:assigns, :jsonb, null: false)
      add(:args, :jsonb, null: false)

      add(:status, :integer)
      add(:response, :jsonb)

      add(:error, :string)
      add(:exception, :text)
      add(:trace_id, :bigint)

      timestamps()
    end
  end
end
