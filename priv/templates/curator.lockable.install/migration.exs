defmodule <%= inspect schema.repo %>.Migrations.AddLockableToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:failed_attempts, :integer, default: 0)
      add(:locked_at, :utc_datetime)
    end
  end
end
