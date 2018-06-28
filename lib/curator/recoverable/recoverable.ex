defmodule Curator.Recoverable do
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
      use Curator.Extension, mod: Curator.Recoverable

      def find_user_by_email(email),
        do: Curator.Recoverable.find_user_by_email(__MODULE__, email)

      def process_email_request(email),
        do: Curator.Recoverable.process_email_request(__MODULE__, email)

      def verify_token(token_id),
        do: Curator.Recoverable.verify_token(__MODULE__, token_id)

      def change_user(user),
        do: Curator.Recoverable.change_user(__MODULE__, user)

      def update_changeset(user, attrs),
        do: Curator.Recoverable.update_changeset(__MODULE__, user, attrs)

      def process_token(token_id, attrs),
        do: Curator.Recoverable.process_token(__MODULE__, token_id, attrs)

      def update_user(user, attrs \\ %{}),
        do: Curator.Recoverable.update_user(__MODULE__, user, attrs)

      defoverridable find_user_by_email: 1
    end
  end

  def process_email_request(mod, email) do
    case mod.find_user_by_email(email) do
      nil ->
        nil
      user ->
        send_recoverable_email(mod, user)
    end
  end

  def verify_token(mod, token_id) do
    with {:ok, %{email: user_email} = user, %{"email" => confirmation_email} = _claims} <- opaque_guardian(mod).resource_from_token(token_id, %{"typ" => "recoverable"}),
         true <- confirmation_email && user_email && confirmation_email == user_email do
      {:ok, user}
    else
      _ ->
        {:error, :invalid}
    end
  end

  def process_token(mod, token_id, attrs) do
    with {:ok, user} <- mod.verify_token(token_id),
         {:ok, user} <- mod.update_user(user, attrs),
         {:ok, _claims} <- opaque_guardian(mod).revoke(token_id) do

      # NOTE: We verified the token email matches the user email, so this will be used by the confirmation module (if enabled)
      curator(mod).extension(:after_password_recovery, [user])

      {:ok, user}
    end
  end

  # Extensions
  def unauthenticated_routes() do
    quote do
      get "/recoverable/new", Auth.RecoverableController, :new
      post "/recoverable/", Auth.RecoverableController, :create
      get "/recoverable/:token_id", Auth.RecoverableController, :edit
      put "/recoverable/:token_id", Auth.RecoverableController, :update
    end
  end

  # Private

  defp send_recoverable_email(mod, user) do
    {:ok, token_id, _claims} = opaque_guardian(mod).encode_and_sign(user, %{email: user.email}, token_type: "recoverable")
    curator(mod).deliver_email(:recoverable, [user, token_id])
  end

  # User Schema / Context

  # This is duplicated and should be moved somewhere shared. Curator? Curator.Schema?
  def find_user_by_email(mod, email) do
    import Ecto.Query, warn: false

    user(mod)
    |> where([u], u.email == ^email)
    |> repo(mod).one()
  end

  def change_user(mod, user) do
    mod.update_changeset(user, %{})
  end

  def update_changeset(mod, user, attrs) do
    changeset = user
    |> cast(attrs, [:password])
    |> validate_required(:password)

    curator(mod).changeset(:update_recoverable_changeset, changeset, attrs)
  end

  def update_user(mod, user, attrs \\ %{}) do
    mod.update_changeset(user, attrs)
    |> repo(mod).update()
  end

  # Config
  defp curator(mod) do
    mod.config(:curator)
  end

  defp opaque_guardian(mod) do
    curator(mod).config(:opaque_guardian)
  end

  defp user(mod) do
    curator(mod).config(:user)
  end

  defp repo(mod) do
    curator(mod).config(:repo)
  end
end