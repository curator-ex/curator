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

  def authenticate_user(mod, %{"email" => email, "password" => password}) do
    authenticate_user(mod, %{email: email, password: password})
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

  # Extensions

  # def curator_schema do
  #   quote do
  #     field :password, :string, virtual: true
  #     field :password_hash, :string
  #   end
  # end

  # def curator_fields do
  #   [:password]
  # end

  # def curator_validation(changeset) do
  #   put_password_hash(changeset)
  # end

  def unauthenticated_routes() do
    quote do
      # Prevent ueberauth from using 'session' as a provider
      get "/session", Auth.SessionController, :new
      post "/session", Auth.SessionController, :create
    end
  end

  # Private

  defp verify_password(nil, _password) do
    Bcrypt.dummy_checkpw()
    false
  end

  # A password_hash should never be missing...
  # Unless curator was installed without this module at first...
  defp verify_password(user, password) do
    if user.password_hash do
      Bcrypt.checkpw(password, user.password_hash)
    else
      Bcrypt.dummy_checkpw()
      false
    end
  end

  # TODO: These need to get on the user module...
  # defp put_password_hash(%Ecto.Changeset{valid?: true, changes: %{password: password}} = changeset) do
  #   change(changeset, Bcrypt.add_hash(password))
  # end

  # defp put_password_hash(changeset), do: changeset

  # Config
  def curator(mod) do
    apply(mod, :config, [:curator])
  end
end
