defmodule <%= inspect context.web_module %>.Auth.ErrorHandler do
  use <%= inspect context.web_module %>, :controller

  def delete(conn, _params) do
    conn
    |> Curator.PlugHelper.sign_out
    |> put_flash(:info, "You have been signed out")
    |> redirect(to: page_path(conn, :index))
  end
end
