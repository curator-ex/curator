defmodule <%= inspect context.web_module %>.Auth.Guardian do
  use Guardian, otp_app: :<%= Mix.Phoenix.otp_app() %>

  def subject_for_token(resource, _claims) do
    sub = to_string(resource.id)
    {:ok, sub}
  end

  def resource_from_claims(claims) do
    claims["sub"]
    |> <%= inspect context.module %>.get_user()
  end

  def fetch_secret_key do
    System.get_env("SECRET_KEY_BASE") || raise "expected the SECRET_KEY_BASE environment variable to be set"
  end
end
