defmodule <%= inspect context.web_module %>.Auth.RegistrationController do
  use <%= inspect context.web_module %>, :controller

  alias <%= inspect schema.module %>
  alias <%= inspect context.web_module %>.Auth.Registerable

  plug Curator.Plug.EnsureNoResource when action in [:new, :create]
  plug Curator.Plug.EnsureResource when action not in [:new, :create]

  def new(conn, _params) do
    changeset = Registerable.change_<%= schema.singular %>(%<%= inspect schema.alias %>{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{<%= inspect schema.singular %> => <%= schema.singular %>_params}) do
    case Registerable.create_<%= schema.singular %>(<%= schema.singular %>_params) do
      {:ok, _<%= schema.singular %>} ->
        conn
        |> put_flash(:info, "Account created successfully.")
        |> redirect(to: registration_path(conn, :show))
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
        |> redirect(to: registration_path(conn, :show))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", <%= schema.singular %>: <%= schema.singular %>, changeset: changeset)
    end
  end

  def delete(conn, _params) do
    <%= schema.singular %> = current_resource(conn)
    {:ok, _<%= schema.singular %>} = Registerable.delete_<%= schema.singular %>(<%= schema.singular %>)

    conn
    |> put_flash(:info, "Account deleted successfully.")
    |> redirect(to: session_path(conn, :new))
  end

  defp current_resource(conn) do
    <%= inspect context.web_module %>.Auth.Curator.current_resource(conn)
  end
end
