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

  @token_typ "recoverable"

  defmacro __using__(opts \\ []) do
    quote do
      use Curator.Config, unquote(opts)
      use Curator.Impl, mod: Curator.Recoverable

      def process_email_request(email),
        do: Curator.Recoverable.process_email_request(__MODULE__, email)

      def verify_token(token_id),
        do: Curator.Recoverable.verify_token(__MODULE__, token_id)

      def change_user(user),
        do: Curator.Recoverable.change_user(__MODULE__, user)

      def process_token(token_id, attrs),
        do: Curator.Recoverable.process_token(__MODULE__, token_id, attrs)

    end
  end

  def process_email_request(mod, email) do
    case curator(mod).find_user_by_email(email) do
      nil ->
        nil
      user ->
        send_recoverable_email(mod, user)
    end
  end

  def verify_token(mod, token_id) do
    with {:ok, %{email: user_email} = user, %{"email" => confirmation_email} = _claims} <- opaque_guardian(mod).resource_from_token(token_id, %{"typ" => @token_typ}),
         true <- confirmation_email && user_email && confirmation_email == user_email do
      {:ok, user}
    else
      _ ->
        {:error, :invalid}
    end
  end

  def process_token(mod, token_id, attrs) do
    with {:ok, user} <- mod.verify_token(token_id),
         {:ok, user} <- update_user(mod, user, attrs),
         {:ok, _claims} <- opaque_guardian(mod).revoke(token_id) do

      # NOTE: We verified the token email matches the user email, so this will be used by the confirmation module (if enabled)
      curator(mod).extension(:after_password_recovery, [user])

      {:ok, user}
    end
  end

  # Extensions
  def unauthenticated_routes(_mod) do
    quote do
      get "/recoverable/new", Auth.RecoverableController, :new
      post "/recoverable/", Auth.RecoverableController, :create
      get "/recoverable/:token_id", Auth.RecoverableController, :edit
      put "/recoverable/:token_id", Auth.RecoverableController, :update
    end
  end

  # Private

  defp send_recoverable_email(mod, user) do
    {:ok, token_id, _claims} = opaque_guardian(mod).encode_and_sign(user, %{email: user.email}, token_type: @token_typ)
    curator(mod).deliver_email(:recoverable, [user, token_id])
  end

  # User Schema / Context

  def change_user(mod, user) do
    update_changeset(mod, user, %{})
  end

  defp update_changeset(mod, user, attrs) do
    changeset = user
    |> cast(attrs, [:password])
    |> validate_required(:password)

    curator(mod).changeset(:update_recoverable_changeset, changeset, attrs)
  end

  defp update_user(mod, user, attrs) do
    update_changeset(mod, user, attrs)
    |> repo(mod).update()
  end

  # Config
end
