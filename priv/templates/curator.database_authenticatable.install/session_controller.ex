defmodule <%= inspect context.web_module %>.Auth.SessionController do
  use <%= inspect context.web_module %>, :controller

  def new(conn, _params) do
    render(conn, "new.html")
  end

  def create(conn, %{"user" => user_params}) do
    case <%= inspect context.web_module %>.Auth.DatabaseAuthenticatable.authenticate_user(user_params) do
      {:ok, user} ->
        case <%= inspect context.web_module %>.Auth.Curator.before_sign_in(user) do
          :ok ->
            conn
            |> put_flash(:info, "Successfully authenticated.")
            |> <%= inspect context.web_module %>.Auth.Curator.sign_in(user)
            |> <%= inspect context.web_module %>.Auth.Curator.after_sign_in(user)
            |> redirect(to: "/")
          {:error, error} ->
            <%= inspect context.web_module %>.Auth.ErrorHandler.auth_error(conn, error, [])
        end
      {:error, _} ->
        conn
        |> put_flash(:error, "Invalid Credentials")
        |> render("new.html")
    end
  end

  def delete(conn, _params) do
    conn
    |> <%= inspect context.web_module %>.Auth.Curator.sign_out
    |> put_flash(:info, "You have been signed out")
    |> redirect(to: page_path(conn, :index))
  end
end
