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
        case Curator.active_for_authentication?(<%= schema.singular %>) do
          :ok ->
            conn
            |> put_flash(:info, "Successfully authenticated.")
            |> <%= inspect context.web_module %>.Auth.Curator.sign_in(user)
            |> <%= inspect context.web_module %>.Auth.Curator.after_sign_in(user)
            |> <%= inspect context.web_module %>.Auth.Curator.redirect_after_sign_in()
          {:error, {:approvable, :account_not_approved}} ->
            conn
            |> put_flash(:error, "You will receive an email when your account is approved")
            |> redirect(to: session_path(conn, :new))
        end
      {:error, _changeset} ->
        <%= inspect context.web_module %>.Auth.ErrorHandler.auth_error(conn, {:ueberauth, :invalid_user}, [])
    end
  end
end
