defmodule Curator.DatabaseAuthenticatable do
  @moduledoc """
  TODO

  Must implement find_user_by_email

  Extensions
  verify_password_failure
  """

  use Curator.Extension
  import Ecto.Changeset

  alias Comeonin.Bcrypt

  defmacro __using__(opts \\ []) do
    quote do
      use Curator.Config, unquote(opts)
      use Curator.Extension, mod: Curator.DatabaseAuthenticatable

      def authenticate_user(params) do
        Curator.DatabaseAuthenticatable.authenticate_user(__MODULE__, params)
      end

      defoverridable authenticate_user: 1
    end
  end

  def authenticate_user(mod, %{email: email, password: password}) do
    user = apply(mod, :find_user_by_email, [email])

    if verify_password(user, password) do
      {:ok, user}
    else
      if user do
        curator(mod).extension(:verify_password_failure, [user])
      end

      {:error, :invalid_credentials}
    end
  end

  def curator_schema do
    quote do
      field :password, :string, virtual: true
      field :password_hash, :string
    end
  end

  def curator_fields do
    [:password]
  end

  def curator_validation(changeset) do
    put_password_hash(changeset)
  end

  defp put_password_hash(%Ecto.Changeset{valid?: true, changes: %{password: password}} = changeset) do
    change(changeset, Comeonin.Bcrypt.add_hash(password))
  end

  defp put_password_hash(changeset), do: changeset

  # Private

  defp verify_password(nil, _password) do
    Bcrypt.dummy_checkpw()
    false
  end

  defp verify_password(user, password) do
    Bcrypt.checkpw(password, user.password_hash)
  end

  # Config
  def curator(mod) do
    apply(mod, :config, [:curator])
  end
end
