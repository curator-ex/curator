defmodule <%= inspect context.web_module %>.Auth.ErrorHandler do
  use <%= inspect context.web_module %>, :controller

  def auth_error(conn, {:no_session, _reason}, _opts) do
    conn
    |> put_flash(:error, "Please sign in")
    |> redirect(to: "/")
  end

  def auth_error(conn, {type, reason}, _opts) do
    conn
    |> put_flash(:error, reason)
    |> redirect(to: "/")
  end
end
