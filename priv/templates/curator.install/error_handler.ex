defmodule <%= inspect context.web_module %>.Auth.ErrorHandler do
  use <%= inspect context.web_module %>, :controller

  def unauthenticated(conn) do
    conn
    |> put_flash(:error, "Please sign in")
    |> redirect(to: page_path(conn, :index))
  end

  def unauthorized(conn) do
    conn
    |> put_flash(:error, "You do not have permission to access this resource")
    |> redirect(to: page_path(conn, :index))
  end
end
