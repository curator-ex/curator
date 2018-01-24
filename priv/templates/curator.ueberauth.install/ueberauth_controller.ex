defmodule <%= inspect context.web_module %>.Auth.UeberauthController do
  use <%= inspect context.web_module %>, :controller

  plug Ueberauth

  alias Ueberauth.Strategy.Helpers

  def request(conn, _params) do
    render(conn, "request.html", callback_url: Helpers.callback_url(conn))
  end

  def callback(%{assigns: %{ueberauth_failure: _fails}} = conn, _params) do
    conn
    |> put_flash(:error, "Failed to authenticate.")
    |> redirect(to: "/")
  end

  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    case <%= context.module %>.find_or_create_from_auth(auth) do
      {:ok, user} ->
        case <%= inspect context.web_module %>.Auth.Curator.before_sign_in(user) do
          :ok ->
            conn
            |> put_flash(:info, "Successfully authenticated.")
            |> <%= inspect context.web_module %>.Auth.Curator.sign_in(user)
            |> <%= inspect context.web_module %>.Auth.Curator.after_sign_in(user)
            |> redirect(to: "/")
          {:error, error} ->
            conn
            |> put_flash(:error, error)
            |> redirect(to: "/")
        end
      {:error, _changeset} ->
        conn
        |> put_flash(:error, "Invalid User")
        |> redirect(to: "/")
    end
  end
end
