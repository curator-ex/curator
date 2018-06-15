defmodule <%= inspect schema.repo %>.Migrations.AddDatabaseAuthenticatableToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:password_hash, :string)
    end
  end
end
