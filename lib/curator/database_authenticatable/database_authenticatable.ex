defmodule Curator.DatabaseAuthenticatable do
  @moduledoc """
  TODO

  Must implement find_user_by_email

  Options
  curator (required)
  crypto_mod (optional) default: Comeonin.Bcrypt

  Extensions
  verify_password_failure
  """

  use Curator.Extension
  import Ecto.Changeset

  defmacro __using__(opts \\ []) do
    quote do
      use Curator.Config, unquote(opts)
      use Curator.Extension, mod: Curator.DatabaseAuthenticatable

      def authenticate_user(params) do
        Curator.DatabaseAuthenticatable.authenticate_user(__MODULE__, params)
      end

      def changeset(user, attrs) do
        Curator.DatabaseAuthenticatable.changeset(__MODULE__, user, attrs)
      end

      defoverridable authenticate_user: 1,
                     changeset: 2
    end
  end

  def authenticate_user(mod, %{"email" => email, "password" => password}) do
    authenticate_user(mod, %{email: email, password: password})
  end

  def authenticate_user(mod, %{email: email, password: password}) do
    user = apply(mod, :find_user_by_email, [email])

    if verify_password(mod, user, password) do
      {:ok, user}
    else
      if user do
        curator(mod).extension(:verify_password_failure, [user])
      end

      {:error, :invalid_credentials}
    end
  end

  # Extensions

  def unauthenticated_routes() do
    quote do
      # Prevent ueberauth from using 'session' as a provider
      get "/session", Auth.SessionController, :new
      post "/session", Auth.SessionController, :create
    end
  end

  # Private

  defp verify_password(mod, nil, _password) do
    crypto_mod(mod).dummy_checkpw()
    false
  end

  # A password_hash should never be missing...
  # Unless curator was installed without this module at first...
  defp verify_password(mod, user, password) do
    if user.password_hash do
      crypto_mod(mod).checkpw(password, user.password_hash)
    else
      crypto_mod(mod).dummy_checkpw()
      false
    end
  end

  # User Schema
  def changeset(mod, user, attrs) do
    user
    |> cast(attrs, [:password])
    |> put_password_hash(mod)
  end

  defp put_password_hash(%Ecto.Changeset{valid?: true, changes: %{password: password}} = changeset, mod) do
    change(changeset, crypto_mod(mod).add_hash(password))
  end

  defp put_password_hash(changeset, _mod), do: changeset

  # Config
  def curator(mod) do
    apply(mod, :config, [:curator])
  end

  def crypto_mod(mod) do
    apply(mod, :config, [:crypto_mod, Comeonin.Bcrypt])
  end
end
