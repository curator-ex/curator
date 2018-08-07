defmodule <%= inspect schema.repo %>.Migrations.AddApprovableToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:approval_status, :string, default: "pending")
      add(:approval_at, :utc_datetime)
      add(:approver_id,:integer)
      # add(:approver_id, references(:users, on_delete: :nothing))
    end

    # create index(:users, [:approver_id])
  end
end
