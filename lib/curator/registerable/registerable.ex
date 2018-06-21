defmodule Curator.Registerable do
  @moduledoc """
  TODO

  Options:

  * `curator` (required)

  Extensions:

  N/A

  """

  use Curator.Extension
  import Ecto.Changeset

  defmacro __using__(opts \\ []) do
    quote do
      use Curator.Config, unquote(opts)
      use Curator.Extension, mod: Curator.Registerable

      def change_user(user) do
        Curator.Registerable.change_user(__MODULE__, user)
      end

      def create_changeset(user, attrs) do
        Curator.Registerable.create_changeset(__MODULE__, user, attrs)
      end

      def create_user(attrs \\ %{}) do
        Curator.Registerable.create_user(__MODULE__, attrs)
      end

      def update_changeset(user, attrs) do
        Curator.Registerable.update_changeset(__MODULE__, user, attrs)
      end

      def update_user(user, attrs \\ %{}) do
        Curator.Registerable.update_user(__MODULE__, user, attrs)
      end

      def delete_user(user) do
        Curator.Registerable.delete_user(__MODULE__, user)
      end

      defoverridable change_user: 1,
                     create_changeset: 2,
                     create_user: 1,
                     update_changeset: 2,
                     update_user: 2,
                     delete_user: 1
    end
  end

  # Extensions

  def unauthenticated_routes() do
    quote do
      resources "/registrations", Auth.RegistrationController, only: [:new, :create]
    end
  end

  def authenticated_routes() do
    quote do
      get "/registrations/edit", Auth.RegistrationController, :edit
      get "/registrations", Auth.RegistrationController, :show
      put "/registrations", Auth.RegistrationController, :update, as: nil
      patch "/registrations", Auth.RegistrationController, :update
      delete "/registrations", Auth.RegistrationController, :delete
    end
  end

  # User Schema / Context
  def change_user(mod, user) do
    mod.create_changeset(user, %{})
  end

  def create_changeset(_mod, user, attrs) do
    user
    |> cast(attrs, [:email])
    |> validate_required([:email])
    |> unique_constraint(:email)
  end

  def create_user(mod, attrs \\ %{}) do
    user = user(mod)
    |> struct()

    mod.create_changeset(user, attrs)
    |> repo(mod).insert()
  end

  def update_changeset(_mod, user, attrs) do
    user
    |> cast(attrs, [:email])
    |> validate_required([:email])
    |> unique_constraint(:email)
  end

  def update_user(mod, user, attrs \\ %{}) do
    mod.update_changeset(user, attrs)
    |> repo(mod).update()
  end

  def delete_user(mod, user) do
    repo(mod).delete(user)
  end

  # Config
  def curator(mod) do
    mod.config(:curator)
  end

  def user(mod) do
    curator(mod).config(:user)
  end

  def repo(mod) do
    curator(mod).config(:repo)
  end
end
