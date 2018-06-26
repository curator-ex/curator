defmodule <%= inspect context.web_module %>.Auth.Email do
  use Phoenix.Swoosh, view: <%= inspect context.web_module %>.Auth.EmailView, layout: {<%= inspect context.web_module %>.Auth.LayoutView, :email}
  alias Swoosh.Email

  # def confirmation(user, token_id) do
  #   url = HoustonWeb.Router.Helpers.confirmation_url(HoustonWeb.Endpoint, :edit, token_id)

  #   %Email{}
  #   |> from(email_from())
  #   |> to(email_to(user))
  #   |> subject("#{site_name()}: Confirm Your Account")
  #   |> render_body("confirmation.html", %{url: url})
  # end

  # defp site_name do
  #   "<%= inspect context.web_module %>"
  # end

  # defp email_from do
  #   {site_name(), "no-reply@todo.com"}
  # end

  # defp email_to(%{email: email}) do
  #   email
  # end
end
