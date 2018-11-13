defmodule <%= inspect context.web_module %>.Auth.LockableController do
  use <%= inspect context.web_module %>, :controller

  alias <%= inspect context.web_module %>.Auth.Lockable

  def edit(conn, %{"token_id" => token_id}) do
    case Lockable.process_token(token_id) do
      {:ok, _user} ->
        conn
        |> put_flash(:info, "Account unlocked. Please sign in.")
        |> redirect(to: Routes.session_path(conn, :new))
      {:error, _} ->
        conn
        |> put_flash(:info, "Token is invalid.")
        |> redirect(to: Routes.session_path(conn, :new))
    end
  end
end
