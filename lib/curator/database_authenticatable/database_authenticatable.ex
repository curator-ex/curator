defmodule Curator.DatabaseAuthenticatable do
  @moduledoc """
  TODO

  Options:

  * `curator` (required)
  * `crypto_mod` (optional) default: Comeonin.Bcrypt

  Extensions:

  * verify_password_failure (called after each incorrect password attempt)

  """

  use Curator.Extension
  import Ecto.Changeset

  defmacro __using__(opts \\ []) do
    quote do
      use Curator.Config, unquote(opts)
      use Curator.Extension, mod: Curator.DatabaseAuthenticatable

      def find_user_by_email(email) do
        Curator.DatabaseAuthenticatable.find_user_by_email(__MODULE__, email)
      end

      def authenticate_user(params) do
        Curator.DatabaseAuthenticatable.authenticate_user(__MODULE__, params)
      end

      def create_changeset(user, attrs) do
        Curator.DatabaseAuthenticatable.create_changeset(__MODULE__, user, attrs)
      end

      def update_changeset(user, attrs) do
        Curator.DatabaseAuthenticatable.update_changeset(__MODULE__, user, attrs)
      end

      def put_password_hash(changeset) do
        Curator.DatabaseAuthenticatable.put_password_hash(changeset, __MODULE__)
      end

      # Curator.Registerable changeset
      def create_registerable_changeset(changeset, attrs) do
        create_changeset(changeset, attrs)
      end

      # Curator.Registerable changeset
      def update_registerable_changeset(changeset, attrs) do
        update_changeset(changeset, attrs)
      end

      # Curator.Recoverable changeset
      def update_recoverable_changeset(changeset, attrs) do
        update_changeset(changeset, attrs)
      end

      defoverridable find_user_by_email: 1,
                     create_changeset: 2,
                     update_changeset: 2
    end
  end

  def authenticate_user(mod, %{"email" => email, "password" => password}) do
    authenticate_user(mod, %{email: email, password: password})
  end

  def authenticate_user(mod, %{email: email, password: password}) do
    user = mod.find_user_by_email(email)

    if verify_password(mod, user, password) do
      {:ok, user}
    else
      if user do
        curator(mod).extension(:verify_password_failure, [user])

        # TODO: Do I like this syntax better?
        # curator(mod).extension(:after_verify_password, [user, result])
      end

      {:error, :invalid_credentials}
    end
  end

  # Extensions

  def unauthenticated_routes() do
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

  # This is duplicated and should be moved somewhere shared. Curator? Curator.Schema?
  def find_user_by_email(mod, email) do
    import Ecto.Query, warn: false

    user(mod)
    |> where([u], u.email == ^email)
    |> repo(mod).one()
  end

  # A more complex password scheme
  # def create_changeset(mod, user, attrs) do
  #   user
  #   |> cast(attrs, [:password])
  #   |> validate_confirmation(:password, required: true)
  #   |> validate_required(:password)
  #   |> validate_length(:password, min: 8)
  #   |> put_password_hash(__MODULE__)
  # end

  def create_changeset(mod, user, attrs) do
    user
    |> cast(attrs, [:password])
    |> validate_confirmation(:password)
    |> validate_required(:password)
    |> put_password_hash(mod)
  end

  def update_changeset(mod, user, attrs) do
    user
    |> cast(attrs, [:password])
    |> validate_confirmation(:password)
    |> put_password_hash(mod)
  end

  def put_password_hash(%Ecto.Changeset{valid?: true, changes: %{password: password}} = changeset, mod) do
    change(changeset, crypto_mod(mod).add_hash(password))
  end

  def put_password_hash(changeset, _mod), do: changeset

  # Config
  defp curator(mod) do
    mod.config(:curator)
  end

  defp crypto_mod(mod) do
    mod.config(:crypto_mod, Comeonin.Bcrypt)
  end

  defp user(mod) do
    curator(mod).config(:user)
  end

  defp repo(mod) do
    curator(mod).config(:repo)
  end
end
