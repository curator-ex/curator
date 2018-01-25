defmodule <%= inspect context.web_module %>.Auth.ErrorHandler do
  use <%= inspect context.web_module %>, :controller

  def auth_error(conn, error, _opts) do
    conn
    |> put_flash(:error, translate_error(error))
    |> redirect(to: "/auth/session/new")
  end

  # From Guardian.Plug.LoadResource
  defp translate_error({:unauthenticated, :unauthenticated}), do: "Please Sign In"

  # From Guardian.Plug.LoadResource
  defp translate_error({:no_resource_found, :no_resource_found}), do: "Please Sign In"

  # Add Additional Translations as needed:
  # From Curator.Timeoutable.Plug
  # defp translate_error({:timeoutable, :timeout}), do: "You have been signed out due to inactivity"

  defp translate_error({_type, reason}), do: reason
end
