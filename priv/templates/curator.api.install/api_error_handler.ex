defmodule <%= inspect context.web_module %>.Auth.ApiErrorHandler do
  use <%= inspect context.web_module %>, :controller

  def auth_error(conn, error, _opts) do
    conn
    |> put_status(401)
    |> json(%{error: translate_auth_error(error)})
  end

  # From Guardian.Plug.VerifyHeader
  defp translate_auth_error({:invalid_token, :invalid}), do: "not_authorized"

  defp translate_auth_error({:invalid_token, "typ"}), do: "not_authorized"

  # From Curator.Plug.LoadResource
  defp translate_auth_error({:load_resource, :no_resource_found}), do: "not_authorized"

  defp translate_auth_error({:load_resource, :no_claims}), do: "no_api_token"

  defp translate_auth_error({_type, reason}), do: reason
end
