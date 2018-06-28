
  def confirmation(user, token_id) do
    url = <%= inspect context.web_module %>.Router.Helpers.confirmation_url(<%= inspect context.web_module %>.Endpoint, :edit, token_id)

    %Email{}
    |> from(email_from())
    |> to(email_to(user))
    |> subject("#{site_name()}: Confirm Your Account")
    |> render_body("confirmation.html", %{url: url})
  end
