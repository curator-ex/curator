
  def recoverable(user, token_id) do
    url = <%= inspect context.web_module %>.Router.Helpers.recoverable_url(<%= inspect context.web_module %>.Endpoint, :edit, token_id)

    %Email{}
    |> from(email_from())
    |> to(email_to(user))
    |> subject("#{site_name()}: Forgotten Password")
    |> render_body("recoverable.html", %{url: url})
  end
