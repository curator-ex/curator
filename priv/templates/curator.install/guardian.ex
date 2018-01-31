defmodule <%= inspect context.web_module %>.Auth.Guardian do
  use Guardian, otp_app: :<%= Mix.Phoenix.otp_app() %>

  def subject_for_token(resource, _claims) do
    sub = to_string(resource.id)
    {:ok, sub}
  end

  def resource_from_claims(claims) do
    id = claims["sub"]
    case <%= inspect context.module %>.get_user(id) do
      nil -> {:error, :no_resource_found}
      resource -> {:ok, resource}
    end
  end
end
