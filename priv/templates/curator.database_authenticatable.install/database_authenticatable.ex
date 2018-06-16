defmodule <%= inspect context.web_module %>.Auth.DatabaseAuthenticatable do
  use Curator.DatabaseAuthenticatable,
    otp_app: :<%= Mix.Phoenix.otp_app() %>,
    curator: <%= inspect context.web_module %>.Auth.Curator

  def find_user_by_email(email) do
    <%= inspect context.module %>.find_user_by_email(email)
  end
end
