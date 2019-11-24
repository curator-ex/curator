defmodule Curator.Guardian.Token.Opaque.ContextAdapter do
  defmacro __using__(opts \\ []) do
    context = Keyword.fetch!(opts, :context)

    quote do
      @behaviour Curator.Guardian.Token.Opaque.Persistence

      def get_token(id) do
        unquote(context).get_token(id)
      end

      # NOTE: We pull user_id & description out of claims
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

        unquote(context).create_token(attrs)
      end

      def delete_token(id) do
        case get_token(id) do
          {:ok, token} ->
            unquote(context).delete_token(token)
          result ->
            result
        end
      end
    end
  end
end
