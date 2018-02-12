defmodule <%= inspect context.web_module %>.Auth.ErrorHandler do
  use <%= inspect context.web_module %>, :controller

  def auth_error(conn, error, _opts) do
    conn
    |> <%= inspect context.web_module %>.Auth.Guardian.Plug.sign_out()
    |> put_flash(:error, translate_error(error))
    |> redirect(to: "/auth/session/new")
  end

  # From Guardian.Plug.VerifySession
  defp translate_auth_error({:invalid_token, :token_expired}), do: "You have been signed out due to inactivity"

  # From Curator.Plug.LoadResource
  defp translate_error({:load_resource, :no_resource_found}), do: "Please Sign In"

  defp translate_error({:load_resource, :no_claims}), do: "Please Sign In"

  # Add Additional Translations as needed:
  # From Curator.Timeoutable.Plug
  # defp translate_auth_error({:timeoutable, :timeout}), do: "You have been signed out due to inactivity"

  # From Curator.Ueberauth
  # defp translate_auth_error({:ueberauth, :invalid_user}), do: "Sorry, your email is not currently authorized to access this system"

  defp translate_error({_type, reason}), do: reason
end
