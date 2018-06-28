defmodule <%= inspect context.web_module %>.Auth.RecoverableController do
  use <%= inspect context.web_module %>, :controller

  alias <%= inspect context.web_module %>.Auth.Recoverable

  plug Curator.Plug.EnsureNoResource

  def new(conn, _params) do
    render(conn, "new.html")
  end

  def create(conn, %{"user" => %{"email" => email}}) when email != "" do
    Recoverable.process_email_request(email)

    conn
    |> put_flash(:error, "Recoverable email sent")
    |> redirect(to: session_path(conn, :new))
  end

  def create(conn, _params) do
    conn
    |> put_flash(:error, "Please enter an email")
    |> render("new.html")
  end

  def edit(conn, %{"token_id" => token_id}) do
    case Recoverable.verify_token(token_id) do
      {:ok, user} ->
        changeset = Recoverable.change_user(user)
        render(conn, "edit.html", changeset: changeset, token_id: token_id)
      {:error, _} ->
        conn
        |> put_flash(:info, "token is invalid.")
        |> redirect(to: session_path(conn, :new))
    end
  end

  def update(conn, %{"token_id" => token_id, "user" => user_params}) do
    case Recoverable.process_token(token_id, user_params) do
      {:ok, _user} ->
        conn
        |> put_flash(:info, "Passsword was updated successfully. Please log in.")
        |> redirect(to: session_path(conn, :new))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", changeset: changeset, token_id: token_id)
      {:error, _} ->
        conn
        |> put_flash(:info, "token is invalid.")
        |> redirect(to: session_path(conn, :new))
    end
  end
end
