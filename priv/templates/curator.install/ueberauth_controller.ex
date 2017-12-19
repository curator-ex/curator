if Code.ensure_loaded?(Curator.Config) && Curator.Config.module_enabled?(Curator.Ueberauth) do
  defmodule <%= inspect context.web_module %>.Auth.UeberauthController do
    use <%= inspect context.web_module %>, :controller

    plug Ueberauth

    # alias Ueberauth.Strategy.Helpers

    # def request(conn, _params) do
    #   render(conn, "request.html", callback_url: Helpers.callback_url(conn))
    # end

    def callback(%{assigns: %{ueberauth_failure: _fails}} = conn, _params) do
      conn
      |> put_flash(:error, "Failed to authenticate.")
      |> redirect(to: "/")
    end

    def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
      case <%= context.module %>.find_or_create_from_auth(auth) do
        {:ok, user} ->
          conn
          |> put_flash(:info, "Successfully authenticated.")
          |> Curator.PlugHelper.sign_in(user)
          |> redirect(to: "/")
        {:error, reason} ->
          conn
          |> put_flash(:error, reason)
          |> redirect(to: "/")
      end
    end
  end
end
