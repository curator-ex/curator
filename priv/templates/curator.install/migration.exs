defmodule <%= base %>.Repo.Migrations.Create<%= scoped %> do
  use Ecto.Migration

  def change do
    create table(:<%= plural %>) do
      add :email, :string

      timestamps()
    end

    create unique_index(:<%= plural %>, [:email])
  end
end
