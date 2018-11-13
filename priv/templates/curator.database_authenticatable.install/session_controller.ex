defmodule <%= inspect context.web_module %>.Auth.SessionController do
  use <%= inspect context.web_module %>, :controller

  plug Curator.Plug.EnsureNoResource when action in [:new, :create]
  plug Curator.Plug.EnsureResource when action not in [:new, :create]

  def new(conn, _params) do
    render(conn, "new.html")
  end

  def create(conn, %{"user" => user_params}) do
    case <%= inspect context.web_module %>.Auth.DatabaseAuthenticatable.authenticate_user(user_params) do
      {:ok, user} ->
          conn
          |> put_flash(:info, "Successfully authenticated.")
          |> <%= inspect context.web_module %>.Auth.Curator.sign_in(user)
          |> <%= inspect context.web_module %>.Auth.Curator.after_sign_in(user)
          |> <%= inspect context.web_module %>.Auth.Curator.redirect_after_sign_in()
        end
      {:error, {:database_authenticatable, :invalid_credentials}} ->
        conn
        |> put_flash(:error, "Invalid credentials")
        |> render("new.html")
      {:error, {:confirmable, :email_not_confirmed}} ->
        conn
        |> put_flash(:error, "Please confirm your account first")
        |> render("new.html")
      {:error, {:lockable, :account_locked}} ->
        conn
        |> put_flash(:error, "Account locked")
        |> render("new.html")
      {:error, {:approvable, :account_not_approved}} ->
        conn
        |> put_flash(:error, "Account not approved")
        |> render("new.html")
      {:error, _error} ->
        conn
        |> put_flash(:error, "Your account is not active...")
        |> redirect(to: Routes.session_path(conn, :new))
    end
  end

  def delete(conn, _params) do
    conn
    |> <%= inspect context.web_module %>.Auth.Curator.sign_out
    |> put_flash(:info, "You have been signed out")
    |> redirect(to: Routes.page_path(conn, :index))
  end
end
