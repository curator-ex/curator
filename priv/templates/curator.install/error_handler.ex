defmodule <%= inspect context.web_module %>.Auth.ErrorHandler do
  use <%= inspect context.web_module %>, :controller

  # From Guardian.Plug.EnsureAuthenticated
  def auth_error(conn, {:unauthenticated, :unauthenticated}, _opts) do
    conn
    |> put_flash(:error, "Please Sign In")
    |> redirect(to: "/auth/session/new")
  end

  # From Guardian.Plug.LoadResource
  def auth_error(conn, {:no_resource_found, :no_resource_found}, _opts) do
    conn
    |> put_flash(:error, "Please Sign In")
    |> redirect(to: "/auth/session/new")
  end

  def auth_error(conn, {_type, reason}, _opts) do
    conn
    |> put_flash(:error, reason)
    |> redirect(to: "/")
  end
end
