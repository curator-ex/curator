defmodule <%= inspect schema.module %> do
  use Ecto.Schema
  import Ecto.Changeset

  schema "auth_tokens" do
    field :claims, :map
    field :description, :string
    field :token, :string

    belongs_to :user, <%= inspect context.module %>.User

    timestamps()
  end

  @doc false
  def changeset(token, attrs) do
    token
    |> cast(attrs, [:token, :description, :claims, :user_id])
    |> validate_required([:token, :claims, :user_id])
    |> unique_constraint(:token)
  end
end
