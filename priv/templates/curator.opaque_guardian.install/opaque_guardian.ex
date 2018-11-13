

defmodule <%= inspect context.web_module %>.Auth.OpaqueGuardian do
  use Guardian, otp_app: :<%= Mix.Phoenix.otp_app() %>,
    token_module: Curator.Guardian.Token.Opaque,
    token_ttl: %{
      "api" => {0, :never},
      "confirmable" => {1, :day},
      "recoverable" => {1, :day},
      "lockable" => {1, :day},
    }

  use Curator.Guardian.Token.Opaque.ContextAdapter, context: <%= inspect context.module %>

  def subject_for_token(resource, _claims) do
    sub = to_string(resource.id)
    {:ok, sub}
  end

  def resource_from_claims(claims) do
    claims["sub"]
    |> <%= inspect context.module %>.get_user()
  end
end
