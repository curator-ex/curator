defmodule <%= inspect context.web_module %>.Auth.SessionController do
  use <%= inspect context.web_module %>, :controller

  plug Curator.Plug.EnsureNoResource when action in [:new, :create]
  plug Curator.Plug.EnsureResource when action not in [:new, :create]

  def new(conn, _params) do
    render(conn, "new.html")
  end

  def delete(conn, _params) do
    conn
    |> <%= inspect context.web_module %>.Auth.Curator.sign_out
    |> put_flash(:info, "You have been signed out")
    |> redirect(to: page_path(conn, :index))
  end
end
