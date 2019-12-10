defmodule <%= inspect context.web_module %>.Auth.RegistrationController do
  use <%= inspect context.web_module %>, :controller

  plug Curator.Plug.EnsureNoResource when action in [:new, :create]
  plug Curator.Plug.EnsureResource when action not in [:new, :create]

  alias <%= inspect schema.module %>
  alias <%= inspect context.web_module %>.Auth.Curator
  alias <%= inspect context.web_module %>.Auth.Registerable

  def new(conn, _params) do
    changeset = Registerable.change_<%= schema.singular %>(%<%= inspect schema.alias %>{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{<%= inspect schema.singular %> => <%= schema.singular %>_params}) do
    case Registerable.create_<%= schema.singular %>(<%= schema.singular %>_params) do
      {:ok, <%= schema.singular %>} ->
        case Curator.active_for_authentication?(<%= schema.singular %>) do
          :ok ->
            conn
            |> put_flash(:info, "Account created successfully. Please sign in.")
            |> redirect(to: Routes.session_path(conn, :new))
          {:error, {:confirmable, :email_not_confirmed}} ->
            conn
            |> put_flash(:error, "Please confirm your account.")
            |> redirect(to: Routes.session_path(conn, :new))
          {:error, {:approvable, :account_not_approved}} ->
            conn
            |> put_flash(:error, "You will receive an email when your account is approved")
            |> redirect(to: Routes.session_path(conn, :new))
          {:error, _error} ->
            conn
            |> put_flash(:error, "Your account is not active...")
            |> redirect(to: Routes.session_path(conn, :new))
        end
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, _params) do
    <%= schema.singular %> = current_resource(conn)
    render(conn, "show.html", <%= schema.singular %>: <%= schema.singular %>)
  end

  def edit(conn, _params) do
    <%= schema.singular %> = current_resource(conn)
    changeset = Registerable.change_<%= schema.singular %>(<%= schema.singular %>)
    render(conn, "edit.html", <%= schema.singular %>: <%= schema.singular %>, changeset: changeset)
  end

  def update(conn, %{<%= inspect schema.singular %> => <%= schema.singular %>_params}) do
    <%= schema.singular %> = current_resource(conn)

    case Registerable.update_<%= schema.singular %>(<%= schema.singular %>, <%= schema.singular %>_params) do
      {:ok, _<%= schema.singular %>} ->
        conn
        |> put_flash(:info, "Account updated successfully.")
        |> redirect(to: Routes.registration_path(conn, :show))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", <%= schema.singular %>: <%= schema.singular %>, changeset: changeset)
    end
  end

  def delete(conn, _params) do
    <%= schema.singular %> = current_resource(conn)
    {:ok, _<%= schema.singular %>} = Registerable.delete_<%= schema.singular %>(<%= schema.singular %>)

    conn
    |> put_flash(:info, "Account deleted successfully.")
    |> redirect(to: Routes.session_path(conn, :new))
  end

  defp current_resource(conn) do
    <%= inspect context.web_module %>.Auth.Curator.current_resource(conn)
  end
end
