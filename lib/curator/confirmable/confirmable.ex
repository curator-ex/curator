defmodule Curator.Confirmable do
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
      use Curator.Impl, mod: Curator.Confirmable

      def verify_confirmed(user),
        do: Curator.Confirmable.verify_confirmed(user)

      def process_token(token_id),
        do: Curator.Confirmable.process_token(__MODULE__, token_id)

      # Extension: Curator.Registerable.create_user\2
      def after_create_registration(user),
        do: Curator.Confirmable.after_create_registration(__MODULE__, user)

      # Extension: Curator.Registerable.update_user\3
      def after_update_registration(user),
        do: Curator.Confirmable.after_update_registration(__MODULE__, user)

      # Extension: Curator.Registerable.update_changeset\3
      def update_registerable_changeset(changeset, attrs),
        do: Curator.Confirmable.update_registerable_changeset(__MODULE__, changeset, attrs)

      # Extension: Curator.Recoverable.process_token\3
      def after_password_recovery(user),
        do: Curator.Confirmable.after_password_recovery(__MODULE__, user)

      # Extension: Curator.Lockable.process_token\3
      def after_lockable(user),
        do: Curator.Confirmable.after_lockable(__MODULE__, user)

    end
  end

  def verify_confirmed(user) do
    if user.email_confirmed_at do
      :ok
    else
      {:error, {:confirmable, :email_not_confirmed}}
    end
  end

  def process_token(mod, token_id) do
    with {:ok, %{email: user_email} = user, %{"email" => confirmation_email} = _claims} <- opaque_guardian(mod).resource_from_token(token_id, %{"typ" => "confirmation"}),
         true <- confirmation_email && user_email && confirmation_email == user_email,
         {:ok, _user} <- confirm_user(mod, user),
         {:ok, _claims} <- opaque_guardian(mod).revoke(token_id) do
      {:ok, user}
    else
      _ ->
        {:error, :invalid}
    end
  end

  # Extensions
  def before_sign_in(_mod, user, _opts) do
    verify_confirmed(user)
  end

  def unauthenticated_routes(_mod) do
    quote do
      # get "/confirmations/new", Auth.ConfirmationController, :new
      # post "/confirmations/:token_id", Auth.ConfirmationController, :create
      get "/confirmations/:token_id", Auth.ConfirmationController, :edit
    end
  end

  def after_create_registration(mod, user) do
    unless user.email_confirmed_at do
      send_confirmation_email(mod, user)
    end
  end

  def after_update_registration(mod, user) do
    unless user.email_confirmed_at do
      send_confirmation_email(mod, user)
    end
  end

  def update_registerable_changeset(_mod, changeset, _attrs) do
    if get_change(changeset, :email) do
      change(changeset, email_confirmed_at: nil)
    else
      changeset
    end
  end

  def after_password_recovery(mod, user) do
    confirm_user_unless_confirmed(mod, user)
  end

  def after_lockable(mod, user) do
    confirm_user_unless_confirmed(mod, user)
  end

  # Private

  defp send_confirmation_email(mod, user) do
    {:ok, token_id, _claims} = opaque_guardian(mod).encode_and_sign(user, %{email: user.email}, token_type: "confirmation")
    curator(mod).deliver_email(:confirmation, [user, token_id])
  end

  defp confirm_user_unless_confirmed(mod, user) do
    unless user.email_confirmed_at do
      confirm_user(mod, user)
    end
  end

  # User Schema / Context

  defp confirm_user(mod, user) do
    user
    |> change(email_confirmed_at: Timex.now())
    |> repo(mod).update()
  end

  # Config
end
