defmodule <%= inspect schema.repo %>.Migrations.CreateAuthTokens do
  use Ecto.Migration

  def change do
    create table(:auth_tokens) do
      add :token, :string
      add :description, :string
      add :claims, :map
      add :typ, :string
      add :exp, :bigint
      add :user_id, references(:users, on_delete: :delete_all)

      timestamps()
    end

    create unique_index(:auth_tokens, [:token])
    create index(:auth_tokens, [:user_id])
    create index(:auth_tokens, [:exp])
  end
end
