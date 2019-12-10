if Code.ensure_loaded?(Phoenix.Swoosh) do
  defmodule <%= inspect context.web_module %>.Auth.Email do
    use Phoenix.Swoosh, view: <%= inspect context.web_module %>.Auth.EmailView, layout: {<%= inspect context.web_module %>.Auth.LayoutView, :email}
    alias Swoosh.Email

    defp site_name do
      "<%= inspect context.web_module %>"
    end

    defp email_from do
      # {site_name(), "no-reply@todo.com"}
      raise "Set an email!"
    end

    defp email_to(%{email: email}) do
      email
    end
  end
end
