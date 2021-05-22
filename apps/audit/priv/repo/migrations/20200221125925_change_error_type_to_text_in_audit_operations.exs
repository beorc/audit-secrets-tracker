defmodule Audit.Repo.Migrations.ChangeErrorTypeToTextInAuditOperations do
  use Ecto.Migration

  def change do
    alter table(:audit_operations) do
      modify(:error, :text)
    end
  end
end
