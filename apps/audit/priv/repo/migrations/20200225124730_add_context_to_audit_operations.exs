defmodule Audit.Repo.Migrations.AddContextToAuditOperations do
  use Ecto.Migration

  def change do
    alter table(:audit_operations) do
      add(:context, :jsonb)
      modify(:assigns, :jsonb, null: true)
      modify(:args, :jsonb, null: true)
    end
  end
end
