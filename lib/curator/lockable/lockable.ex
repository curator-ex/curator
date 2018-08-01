defmodule Curator.Lockable do
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
      use Curator.Extension, mod: Curator.Lockable

      def verify_unlocked(user) do
        Curator.Lockable.verify_unlocked(__MODULE__, user)
      end

      # Extenstion: Curator.DatabaseAuthenticatable.authenticate_user\2
      def after_verify_password_failure(user) do
        Curator.Lockable.after_verify_password_failure(__MODULE__, user)
      end

      # Extenstion: Curator.Recoverable.process_token\3
      def after_password_recovery(user) do
        Curator.Lockable.after_password_recovery(__MODULE__, user)
      end

      def process_email_request(email),
        do: Curator.Lockable.process_email_request(__MODULE__, email)

      def verify_token(token_id),
        do: Curator.Lockable.verify_token(__MODULE__, token_id)

      def process_token(token_id, attrs),
        do: Curator.Lockable.process_token(__MODULE__, token_id, attrs)

      def unlock_user(user, attrs \\ %{}),
        do: Curator.Lockable.unlock_user(__MODULE__, user, attrs)
    end
  end

  def verify_unlocked(mod, user) do
    if locked?(mod, user) do
      {:error, {:lockable, :account_locked}}
    else
      :ok
    end
  end

  def process_email_request(mod, email) do
    case curator(mod).find_user_by_email(email) do
      nil ->
        nil
      user ->
        send_lockable_email(mod, user)
    end
  end

  def verify_token(mod, token_id) do
    with {:ok, %{email: user_email} = user, %{"email" => confirmation_email} = _claims} <- opaque_guardian(mod).resource_from_token(token_id, %{"typ" => "lockable"}),
         true <- confirmation_email && user_email && confirmation_email == user_email do
      {:ok, user}
    else
      _ ->
        {:error, :invalid}
    end
  end

  def process_token(mod, token_id, attrs) do
    with {:ok, user} <- mod.verify_token(token_id),
         {:ok, user} <- mod.unlock_user(user, attrs),
         {:ok, _claims} <- opaque_guardian(mod).revoke(token_id) do

      # NOTE: We verified the token email matches the user email, so this will be used by the confirmation module (if enabled)
      curator(mod).extension(:after_unlocked, [user])

      {:ok, user}
    end
  end

  # Extensions
  def before_sign_in(mod, user, _opts) do
    verify_unlocked(mod, user)
  end

  # def after_sign_in(_conn, user, _opts) do
  #   unlock_user(mod, user)
  # end

  def after_verify_password_failure(mod, %{failed_attempts: failed_attempts, locked_at: locked_at} = user) do
    user = change(user, failed_attempts: failed_attempts + 1)

    user = if failed_attempts >= maximum_attempts(mod) && !locked_at do
      change(user, locked_at: Timex.now())
    else
      user
    end

    repo(mod).update!(user)
  end

  def after_password_recovery(mod, user) do
    if locked?(mod, user) do
      unlock_user(mod, user)
    end
  end

  def unauthenticated_routes(_mod) do
    quote do
      get "/lockable/new", Auth.LockableController, :new
      post "/lockable/", Auth.LockableController, :create
      get "/lockable/:token_id", Auth.LockableController, :edit
    end
  end

  # Private

  defp send_lockable_email(mod, user) do
    {:ok, token_id, _claims} = opaque_guardian(mod).encode_and_sign(user, %{email: user.email}, token_type: "lockable")
    curator(mod).deliver_email(:lockable, [user, token_id])
  end

  defp locked?(mod, user) do
    !!user.locked_at && !lock_expired?(mod, user)
  end

  defp lock_expired?(mod, %{locked_at: locked_at} = _user) do
    if Enum.member?(unlock_strategy(mod), :time) do
      locked_at && Curator.Time.expired?(locked_at, unlock_in(mod))
    else
      false
    end
  end

  # User Schema / Context

  def unlock_user(mod, user) do
    user
    |> change(failed_attempts: 0, locked_at: nil)
    |> repo(mod).update()
  end

  # Config
  defp curator(mod) do
    mod.config(:curator)
  end

  defp opaque_guardian(mod) do
    curator(mod).config(:opaque_guardian)
  end

  # defp user(mod) do
  #   curator(mod).config(:user)
  # end

  defp repo(mod) do
    curator(mod).config(:repo)
  end

  defp maximum_attempts(mod) do
    mod.config(:maximum_attempts, 5)
  end

  defp unlock_strategy(mod)do
    mod.config(:unlock_strategy, [])
  end

  defp unlock_in(mod) do
    mod.config(:unlock_in, [hours: 6])
  end
end
