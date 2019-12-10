defmodule Curator.Ueberauth do
  @moduledoc """
  TODO

  Options:

  N/A

  Extensions:

  N/A

  """

  use Curator.Extension
  import Ecto.Changeset

  defmacro __using__(opts \\ []) do
    quote do
      use Curator.Config, unquote(opts)
      use Curator.Impl, mod: Curator.Ueberauth

      # TODO: Remove from generator and integrate with controller
      # What about workflows that require additional data?
      def find_or_create_from_auth(auth),
        do: Curator.Ueberauth.find_or_create_from_auth(__MODULE__, auth)

      defoverridable find_or_create_from_auth: 1

    end
  end

  def find_or_create_from_auth(mod, auth) do
    %{
      info: %{email: email}
    } = auth

    case repo(mod).get_by(user(mod), email: email) do
      nil ->
        create_user(mod, %{
          email: email,
        })
      user ->
        curator(mod).extension(:after_ueberauth_find_user, [user])

        {:ok, user}
    end
  end

  defp create_changeset(mod, user, attrs) do
    changeset = user
    |> cast(attrs, [:email])
    |> validate_required([:email])
    |> unique_constraint(:email)

    curator(mod).changeset(:create_ueberauth_changeset, changeset, attrs)
  end

  defp create_user(mod, attrs) do
    user = user(mod)
    |> struct()

    result = create_changeset(mod, user, attrs)
    |> repo(mod).insert()

    curator(mod).extension_pipe(:after_ueberauth_create_user, result)
  end

  # Extensions

  def unauthenticated_routes(_mod) do
    quote do
      scope "/auth" do
        get "/:provider", Auth.UeberauthController, :request
        get "/:provider/callback", Auth.UeberauthController, :callback
        post "/:provider/callback", Auth.UeberauthController, :callback
      end
    end
  end
end
