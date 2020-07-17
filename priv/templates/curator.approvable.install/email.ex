
  def approvable(user) do
    # url = <%= inspect context.web_module %>.Router.Helpers.approvable_url(<%= inspect context.web_module %>.Endpoint, :edit, token_id)

    %Email{}
    |> from(email_from())
    |> to(approvable_emails())
    |> subject("#{site_name()}: Account Approval")
    |> render_body("approvable.html", %{email: user.email})
  end

  defp approvable_emails do
    raise "TODO"
  end

  def approved(user) do
    url = <%= inspect context.web_module %>.Endpoint.url()

    %Email{}
    |> from(email_from())
    |> to(email_to(user))
    |> subject("#{site_name()}: Account Approved")
    |> render_body("approved.html", %{url: url})
  end
