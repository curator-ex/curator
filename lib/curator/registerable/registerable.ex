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
      use Curator.Impl, mod: Curator.Registerable

      def change_user(user),
        do: Curator.Registerable.change_user(__MODULE__, user)

      def create_changeset(user, attrs),
        do: Curator.Registerable.create_changeset(__MODULE__, user, attrs)

      def create_user(attrs \\ %{}),
        do: Curator.Registerable.create_user(__MODULE__, attrs)

      def update_changeset(user, attrs),
        do: Curator.Registerable.update_changeset(__MODULE__, user, attrs)

      def update_user(user, attrs \\ %{}),
        do: Curator.Registerable.update_user(__MODULE__, user, attrs)

      def delete_user(user),
        do: Curator.Registerable.delete_user(__MODULE__, user)

      defoverridable change_user: 1,
                     create_changeset: 2,
                     create_user: 1,
                     update_changeset: 2,
                     update_user: 2,
                     delete_user: 1
    end
  end

  # Extensions

  def unauthenticated_routes(_mod) do
    quote do
      resources "/registrations", Auth.RegistrationController, only: [:new, :create]
    end
  end

  def authenticated_routes(_mod) do
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

  def create_changeset(mod, user, attrs) do
    changeset = user
    |> cast(attrs, [:email])
    |> validate_required([:email])
    |> unique_constraint(:email)

    curator(mod).changeset(:create_registerable_changeset, changeset, attrs)
  end

  def create_user(mod, attrs \\ %{}) do
    user = user(mod)
    |> struct()

    result = mod.create_changeset(user, attrs)
    |> repo(mod).insert()

    case result do
      {:ok, user} ->
        curator(mod).extension(:after_create_registration, [user])
      {:error, _} ->
        nil
    end

    result
  end

  def update_changeset(mod, user, attrs) do
    changeset = user
    |> cast(attrs, [:email])
    |> validate_required([:email])
    |> unique_constraint(:email)

    curator(mod).changeset(:update_registerable_changeset, changeset, attrs)
  end

  def update_user(mod, user, attrs \\ %{}) do
    result = mod.update_changeset(user, attrs)
    |> repo(mod).update()

    case result do
      {:ok, user} ->
        curator(mod).extension(:after_update_registration, [user])
      {:error, _} ->
        nil
    end

    result
  end

  def delete_user(mod, user) do
    repo(mod).delete(user)
  end

  # Config
end
