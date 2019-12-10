defmodule Curator.Approvable do
  @moduledoc """
  TODO

  Options:

  * `curator` (required)
  * `email_after` (optional) [:registration || :confirmation]

  Extensions:

  N/A

  """

  use Curator.Extension
  import Ecto.Changeset

  defmacro __using__(opts \\ []) do
    quote do
      use Curator.Config, unquote(opts)
      use Curator.Impl, mod: Curator.Approvable

      def verify_approved(user),
        do: Curator.Approvable.verify_approved(__MODULE__, user)

      def approve_user(user, approver_id \\ 0),
        do: Curator.Approvable.approve_user(__MODULE__, user, approver_id)

      # Extension: Curator.Registerable.create_user\2
      def after_create_registration(result),
        do: Curator.Approvable.after_create_registration(__MODULE__, result)

      # Extension: Curator.Confirmable.confirm_user\2
      def after_confirmation(user),
        do: Curator.Approvable.after_confirmation(__MODULE__, user)

      defoverridable after_create_registration: 1,
                     after_confirmation: 1
    end
  end

  def verify_approved(_mod, user) do
    if approved?(user) do
      :ok
    else
      {:error, {:approvable, :account_not_approved}}
    end
  end

  # Extensions
  def active_for_authentication?(mod, user) do
    verify_approved(mod, user)
  end

  def after_create_registration(mod, {:ok, user}) do
    if !approved?(user) && Enum.member?(email_after(mod), :registration) do
      send_approvable_email(mod, user)
    end

    {:ok, user}
  end

  def after_create_registration(_mod, result), do: result

  def after_confirmation(mod, user) do
    if !approved?(user) && Enum.member?(email_after(mod), :confirmation) do
      send_approvable_email(mod, user)
    end

    user
  end

  # Private

  defp approved?(%{approval_status: approval_status}) do
    approval_status == "approved"
  end

  defp send_approvable_email(mod, user) do
    curator(mod).deliver_email(:approvable, [user])
  end

  # User Schema / Context

  def approve_user(mod, user, approver_id \\ 0) do
    user
    |> change(approval_at: Timex.now(), approval_status: "approved", approver_id: approver_id)
    |> repo(mod).update!()
  end

  # Config
  defp email_after(mod) do
    mod.config(:email_after, [])
  end
end
