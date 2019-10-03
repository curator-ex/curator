defmodule Curator.DatabaseAuthenticatable do
  @moduledoc """
  TODO

  Options:

  * `curator` (required)
  * `crypto_mod` (optional) default: Comeonin.Bcrypt

  Extensions:

  * after_verify_password_failure (called after each incorrect password attempt)

  """

  use Curator.Extension
  import Ecto.Changeset

  defmacro __using__(opts \\ []) do
    quote do
      use Curator.Config, unquote(opts)
      use Curator.Impl, mod: Curator.DatabaseAuthenticatable

      def authenticate_user(params),
        do: Curator.DatabaseAuthenticatable.authenticate_user(__MODULE__, params)

      # A more complex password scheme
      # def create_changeset(user, attrs) do
      #   user
      #   |> cast(attrs, [:password])
      #   |> validate_confirmation(:password, required: true)
      #   |> validate_required(:password)
      #   |> validate_length(:password, min: 8)
      #   |> put_password_hash()
      # end

      def create_changeset(user, attrs),
        do: Curator.DatabaseAuthenticatable.create_changeset(__MODULE__, user, attrs)

      def update_changeset(user, attrs),
        do: Curator.DatabaseAuthenticatable.update_changeset(__MODULE__, user, attrs)

      def put_password_hash(changeset),
        do: Curator.DatabaseAuthenticatable.put_password_hash(changeset, __MODULE__)

      # Curator.Registerable changeset
      def create_registerable_changeset(changeset, attrs),
        do: create_changeset(changeset, attrs)

      # Curator.Registerable changeset
      def update_registerable_changeset(changeset, attrs),
        do: update_changeset(changeset, attrs)

      # Curator.Recoverable changeset
      def update_recoverable_changeset(changeset, attrs),
        do: update_changeset(changeset, attrs)

      defoverridable create_changeset: 2,
                     update_changeset: 2
    end
  end

  def authenticate_user(mod, %{"email" => email, "password" => password}) do
    authenticate_user(mod, %{email: email, password: password})
  end

  def authenticate_user(mod, %{email: email, password: password}) do
    user = curator(mod).find_user_by_email(email)

    if user do
      case curator(mod).active_for_authentication?(user) do
        :ok ->
          if verify_password(mod, user, password) do
            curator(mod).extension(:after_verify_password_success, [user])

            {:ok, user}
          else
            curator(mod).extension(:after_verify_password_failure, [user])

            {:error, {:database_authenticatable, :invalid_credentials}}
          end
        {:error, error} ->
          {:error, error}
      end
    else
      verify_password(mod, nil, password)

      {:error, {:database_authenticatable, :invalid_credentials}}
    end
  end

  # Extensions

  def unauthenticated_routes(_mod) do
    quote do
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
  # Or they went through the ueberauth workflow
  defp verify_password(mod, user, password) do
    if user.password_hash do
      crypto_mod(mod).checkpw(password, user.password_hash)
    else
      crypto_mod(mod).dummy_checkpw()
      false
    end
  end

  # User Schema / Context

  def create_changeset(mod, user, attrs) do
    user
    |> cast(attrs, [:password])
    |> validate_confirmation(:password)
    |> validate_required(:password)
    |> mod.put_password_hash()
  end

  def update_changeset(mod, user, attrs) do
    user
    |> cast(attrs, [:password])
    |> validate_confirmation(:password)
    |> mod.put_password_hash()
  end

  def put_password_hash(%Ecto.Changeset{valid?: true, changes: %{password: password}} = changeset, mod) do
    change(changeset, crypto_mod(mod).add_hash(password))
  end

  def put_password_hash(changeset, _mod), do: changeset

  # Config
  defp crypto_mod(mod) do
    mod.config(:crypto_mod, Comeonin.Bcrypt)
  end

  # TODO: Adjust authenticate_user so it can also work with a `username`
  # defp user_identifier_field do
  #   mod.config(:user_identifier_field, :email)
  # end
end
