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

  @token_typ "confirmable"

  defmacro __using__(opts \\ []) do
    quote do
      use Curator.Config, unquote(opts)
      use Curator.Impl, mod: Curator.Confirmable

      def verify_confirmed(user),
        do: Curator.Confirmable.verify_confirmed(__MODULE__, user)

      def process_token(token_id),
        do: Curator.Confirmable.process_token(__MODULE__, token_id)

      # Extension: Curator.Registerable.create_user\2
      def after_create_registration(result),
        do: Curator.Confirmable.after_create_registration(__MODULE__, result)

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
      def after_unlocked(user),
        do: Curator.Confirmable.after_unlocked(__MODULE__, user)

      # Extension: Curator.Ueberauth.create_user\1
      def after_ueberauth_create_user(result),
        do: Curator.Confirmable.after_ueberauth_create_user(__MODULE__, result)

      # Extension: Curator.Ueberauth.find_or_create_from_auth\1
      # def after_ueberauth_find_user(user),
      #   do: Curator.Confirmable.after_ueberauth_find_user(__MODULE__, user)

      def create_ueberauth_changeset(changeset, attrs),
        do: Curator.Confirmable.create_ueberauth_changeset(__MODULE__, changeset, attrs)

      def confirm_user_unless_confirmed(user),
        do: Curator.Confirmable.confirm_user_unless_confirmed(__MODULE__, user)
    end
  end

  def verify_confirmed(_mod, user) do
    if user.email_confirmed_at do
      :ok
    else
      {:error, {:confirmable, :email_not_confirmed}}
    end
  end

  def process_token(mod, token_id) do
    with {:ok, %{email: user_email} = user, %{"email" => confirmation_email} = _claims} <-
           opaque_guardian(mod).resource_from_token(token_id, %{"typ" => @token_typ}),
         true <- confirmation_email && user_email && confirmation_email == user_email,
         user <- confirm_user(mod, user),
         {:ok, _claims} <- opaque_guardian(mod).revoke(token_id) do
      {:ok, user}
    else
      _ ->
        {:error, :invalid}
    end
  end

  # Extensions
  def active_for_authentication?(mod, user) do
    verify_confirmed(mod, user)
  end

  def unauthenticated_routes(_mod) do
    quote do
      # get "/confirmable/new", Auth.ConfirmableController, :new
      # post "/confirmable/:token_id", Auth.ConfirmableController, :create
      get("/confirmable/:token_id", Auth.ConfirmableController, :edit)
    end
  end

  def after_create_registration(mod, {:ok, user}) do
    unless user.email_confirmed_at do
      send_confirmable_email(mod, user)
    end

    {:ok, user}
  end

  def after_create_registration(_mod, result), do: result

  def after_update_registration(mod, user) do
    unless user.email_confirmed_at do
      send_confirmable_email(mod, user)
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

  def after_unlocked(mod, user) do
    confirm_user_unless_confirmed(mod, user)
  end

  def after_ueberauth_create_user(mod, {:ok, user}) do
    {:ok, confirm_user_unless_confirmed(mod, user)}
  end

  def after_ueberauth_create_user(_mod, result) do
    result
  end

  # def after_ueberauth_find_user(mod, user) do
  #   confirm_user_unless_confirmed(mod, user)
  # end

  def create_ueberauth_changeset(_mod, changeset, _attrs) do
    change(changeset, email_confirmed_at: Timex.now())
  end

  # Private

  defp send_confirmable_email(mod, user) do
    {:ok, token_id, _claims} =
      opaque_guardian(mod).encode_and_sign(user, %{email: user.email}, token_type: @token_typ)

    curator(mod).deliver_email(:confirmable, [user, token_id])
  end

  def confirm_user_unless_confirmed(mod, user) do
    unless user.email_confirmed_at do
      confirm_user(mod, user)
    else
      user
    end
  end

  # User Schema / Context

  defp confirm_user(mod, user) do
    user =
      user
      |> change(email_confirmed_at: Timex.now())
      |> repo(mod).update!()

    curator(mod).extension_pipe(:after_confirmation, user)
  end

  # Config
end
