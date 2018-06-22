defmodule Curator.Confirmable do
  @moduledoc """
  TODO

  Options:

  * `curator` (required)
  * `opaque_guardian` (required)

  Extensions:

  N/A

  """

  use Curator.Extension
  # import Ecto.Changeset

  defmacro __using__(opts \\ []) do
    quote do
      use Curator.Config, unquote(opts)
      use Curator.Extension, mod: Curator.Confirmable

      def verify_confirmed(user) do
        Curator.Confirmable.verify_confirmed(user)
      end

      def after_create_registration(user) do
        Curator.Confirmable.after_create_registration(__MODULE__, user)
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

  # Extensions
  # NOTE: this doesn't take a module, so can't access overrides...
  def before_sign_in(user, _opts) do
    verify_confirmed(user)
  end

  def unauthenticated_routes() do
    quote do
      # get "/confirmations/:token_id", Auth.ConfirmationController, :update
    end
  end

  def after_create_registration(_mod, _user) do
    raise "TODO - Send an email..."
  end

  def update_registerable_changeset(_mod, changeset, attrs) do
    raise "TODO - Mark email_confirmed_at to nil if email changed"
  end

  # Private

  # User Schema / Context

  # Config
  def curator(mod) do
    mod.config(:curator)
  end

  def opaque_guardian(mod) do
    mod.config(:opaque_guardian)
  end

  # def user(mod) do
  #   curator(mod).config(:user)
  # end

  # def repo(mod) do
  #   curator(mod).config(:repo)
  # end
end
