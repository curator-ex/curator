defmodule <%= inspect context.web_module %>.Auth.ConfirmableController do
  use <%= inspect context.web_module %>, :controller

  alias <%= inspect context.web_module %>.Auth.Confirmable

  # def new(conn, _params) do
  #   changeset = Confirmable.change_<%= schema.singular %>(%<%= inspect schema.alias %>{})
  #   render(conn, "new.html", changeset: changeset)
  # end

  # def create(conn, %{<%= inspect schema.singular %> => <%= schema.singular %>_params}) do
  #   case Confirmable.create_<%= schema.singular %>(<%= schema.singular %>_params) do
  #     {:ok, _<%= schema.singular %>} ->
  #       conn
  #       |> put_flash(:info, "Email sent successfully.")
  #       |> redirect(to: registration_path(conn, :show))
  #     {:error, %Ecto.Changeset{} = changeset} ->
  #       render(conn, "new.html", changeset: changeset)
  #   end
  # end

  def edit(conn, %{"token_id" => token_id}) do
    case Confirmable.process_token(token_id) do
      {:ok, _user} ->
        conn
        |> put_flash(:info, "Email confirmed. Please sign in.")
        |> redirect(to: session_path(conn, :new))
      {:error, _} ->
        conn
        |> put_flash(:info, "Token is invalid.")
        |> redirect(to: session_path(conn, :new))
    end
  end
end
