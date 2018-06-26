

defmodule <%= inspect context.web_module %>.Auth.OpaqueGuardian do
  use Guardian, otp_app: :<%= Mix.Phoenix.otp_app() %>,
    token_module: Curator.Guardian.Token.Opaque,
    token_ttl: %{
      "api" => {0, :never},
      "confirmation" => {1, :day},
      "recoverable" => {1, :day},
    }

  def subject_for_token(resource, _claims) do
    sub = to_string(resource.id)
    {:ok, sub}
  end

  def resource_from_claims(claims) do
    claims["sub"]
    |> <%= inspect context.module %>.get_user()
  end

  @behaviour Curator.Guardian.Token.Opaque.Persistence

  def get_token(id) do
    <%= inspect context.module %>.get_token(id)
  end

  # NOTE: We pull user_id & description our of claims
  # We will also use the sub in place of user_id
  # Finally, the token is set here (to a random string)
  def create_token(claims) do
    user_id = Map.get(claims, "user_id") || Map.get(claims, "sub")
    description = Map.get(claims, "description")
    typ = Map.get(claims, "typ")
    exp = Map.get(claims, "exp")

    claims = claims
    |> Map.drop(["user_id", "description"])

    token = Curator.Guardian.Token.Opaque.token_id()

    attrs = %{
      "claims" => claims,
      "user_id" => user_id,
      "description" => description,
      "token" => token,
      "typ" => typ,
      "exp" => exp,
    }

    <%= inspect context.module %>.create_token(attrs)
  end

  def delete_token(id) do
    case get_token(id) do
      {:ok, token} ->
        <%= inspect context.module %>.delete_token(token)
      result ->
        result
    end
  end
end
