defmodule <%= inspect schema.repo %>.Migrations.AddConfirmableToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:email_confirmed_at, :utc_datetime)
    end
  end
end
