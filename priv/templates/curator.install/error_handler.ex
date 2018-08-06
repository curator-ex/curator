defmodule <%= inspect context.web_module %>.Auth.ErrorHandler do
  use <%= inspect context.web_module %>, :controller

  # NOTE: We don't sign out when already authenticated...
  def auth_error(conn, {:ensure_no_resource, :already_authenticated} = error, _opts) do
    conn
    |> put_flash(:error, translate_auth_error(error))
    |> redirect(to: "/")
  end

  def auth_error(conn, error, _opts) do
    conn
    |> <%= inspect context.web_module %>.Auth.Guardian.Plug.sign_out()
    |> <%= inspect context.web_module %>.Auth.Curator.store_return_to_url()
    |> put_flash(:error, translate_error(error))
    |> redirect(to: session_path(conn, :new))
  end

  # From Curator.Plug.EnsureNoResource
  defp translate_auth_error({:ensure_no_resource, :already_authenticated}), do: "Already Authenticated"

  # From Guardian.Plug.VerifySession
  defp translate_auth_error({:invalid_token, :token_expired}), do: "You have been signed out due to inactivity"

  # From Curator.Plug.LoadResource
  defp translate_error({:load_resource, :no_resource_found}), do: "Please Sign In"

  defp translate_error({:load_resource, :no_claims}), do: "Please Sign In"

  # Add Additional Translations as needed:
  # From Curator.Timeoutable
  # defp translate_auth_error({:timeoutable, :timeout}), do: "You have been signed out due to inactivity"

  # From Curator.Ueberauth
  # defp translate_auth_error({:ueberauth, :invalid_user}), do: "Sorry, your email is not currently authorized to access this system"

  # From Curator.Confirmable
  # defp translate_auth_error({:confirmable, :email_not_confirmed}), do: "Sorry, your email has not been confirmed yet"

  # From Curator.Lockable
  # defp translate_auth_error({:lockable, :account_locked}), do: "This accout has been locked"

  defp translate_error({_type, reason}), do: reason
end
