defmodule <%= module %> do
  use <%= base %>.Web, :model

  # Use Curator Modules (as needed).
  # use CuratorDatabaseAuthenticatable.Schema

  schema <%= inspect plural %> do
    field :email, :string

    # Add Curator Module fields (as needed).
    # curator_database_authenticatable_schema
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:email])
    |> validate_required([:email])
    |> validate_format(:email, ~r/@/)
    |> unique_constraint(:email)
  end
end
