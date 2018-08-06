
  def lockable(user, token_id) do
    url = <%= inspect context.web_module %>.Router.Helpers.lockable_url(<%= inspect context.web_module %>.Endpoint, :edit, token_id)

    %Email{}
    |> from(email_from())
    |> to(email_to(user))
    |> subject("#{site_name()}: Confirm Your Account")
    |> render_body("lockable.html", %{url: url})
  end
