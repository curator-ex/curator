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
      use Curator.Extension, mod: Curator.Confirmable

      def verify_confirmed(user) do
        Curator.Confirmable.verify_confirmed(user)
      end

      def process_token(token_id) do
        Curator.Confirmable.process_token(__MODULE__, token_id)
      end

      def after_create_registration(user) do
        Curator.Confirmable.after_create_registration(__MODULE__, user)
      end

      def after_update_registration(user) do
        Curator.Confirmable.after_update_registration(__MODULE__, user)
      end

      def update_registerable_changeset(changeset, attrs) do
        Curator.Confirmable.update_registerable_changeset(__MODULE__, changeset, attrs)
      end

      # NOTE: NO!
      # defoverridable verify_confirmed: 1
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
    with {:ok, %{email: user_email} = user, %{"email" => confirmation_email} = claims} <- opaque_guardian(mod).resource_from_token(token_id, %{"typ" => "confirmation"}),
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
  # NOTE: this doesn't take a module, so can't access overrides...
  def before_sign_in(user, _opts) do
    verify_confirmed(user)
  end

  def unauthenticated_routes() do
    quote do
      # get "/confirmations/new", Auth.ConfirmationController, :new
      # post "/confirmations/:token_id", Auth.ConfirmationController, :create
      get "/confirmations/:token_id", Auth.ConfirmationController, :edit
    end
  end

  def after_create_registration(mod, user) do
    unless user.email_confirmed_at do
      {:ok, token_id, _claims} = opaque_guardian(mod).encode_and_sign(user, %{email: user.email}, token_type: "confirmation")
      curator(mod).deliver_email(:confirmation, [user, token_id])
    end
  end

  def after_update_registration(mod, user) do
    unless user.email_confirmed_at do
      {:ok, token_id, _claims} = opaque_guardian(mod).encode_and_sign(user, %{email: user.email}, token_type: "confirmation")
      curator(mod).deliver_email(:confirmation, [user, token_id])
    end
  end

  def update_registerable_changeset(_mod, changeset, attrs) do
    if get_change(changeset, :email) do
      change(changeset, email_confirmed_at: nil)
    else
      changeset
    end
  end

  # Private

  # User Schema / Context

  defp confirm_user(mod, user) do
    user
    |> change(email_confirmed_at: Timex.now())
    |> repo(mod).update
  end

  # Config
  def curator(mod) do
    mod.config(:curator)
  end

  def opaque_guardian(mod) do
    curator(mod).config(:opaque_guardian)
  end

  def repo(mod) do
    curator(mod).config(:repo)
  end
end
