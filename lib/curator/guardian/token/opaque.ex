defmodule Curator.Guardian.Token.Opaque do
  @moduledoc """
    Opaque token implementation for Guardian.

    Rather than the default JWT implementation, this module expect that a token
    will be an opaque string, that can be looked up (in a persistance module) to
    get the claims. It uses a subset of the standard JWT claims so it will function
    as a drop-in replacement for the default Guardian implementation.

    NOTE: To use this module, the guardian implementation module must
    implement get_token, create_token & delete_token (the
    Curator.Guardian.Token.Opaque.Persistence behaviour). An example can be found in
    the specs (it uses a context and an ecto repo). Redis, Genserver, or other
    stateful implementations can also be used.
   """

  @behaviour Guardian.Token

  @default_token_type "access"

  @token_length 64

  import Guardian, only: [stringify_keys: 1]

  @doc """
  Inspect the token.

  Not applicable (as it's an opaque token)
  """
  def peek(_mod, nil), do: nil

  def peek(_mod, _token_id) do
    nil
  end

  @doc """
  Generate unique token id
  """
  def token_id do
    :crypto.strong_rand_bytes(@token_length) |> Base.encode64 |> binary_part(0, @token_length)
  end

  @doc """
  Builds the default claims (a subset of the JWT claims).

  By default, only typ, and sub are used

  Options:

  Options may override the defaults found in the configuration.

  * `token_type` - Override the default token type
  """
  def build_claims(mod, _resource, sub, claims \\ %{}, options \\ []) do
    claims =
      claims
      |> stringify_keys()
      |> set_type(mod, options)
      |> set_sub(mod, sub, options)

    {:ok, claims}
  end

  defp set_type(%{"typ" => typ} = claims, _mod, _opts) when not is_nil(typ), do: claims

  defp set_type(claims, mod, opts) do
    defaults = apply(mod, :default_token_type, [])
    typ = Keyword.get(opts, :token_type, defaults)
    Map.put(claims, "typ", to_string(typ || @default_token_type))
  end

  defp set_sub(claims, _mod, subject, _opts), do: Map.put(claims, "sub", subject)

  @doc """
  Create a token. Uses the claims, and persists the token.
  Returns the token_id

  """
  def create_token(mod, claims, _options \\ []) do
    with {:ok, token} <- apply(mod, :create_token, [claims]) do
      token_id = token_to_token_id(token)
      {:ok, token_id}
    end
  end

  @doc """
  Find the token and return its claims (or return an error)
  """
  def decode_token(mod, token_id, _options \\ [])
  def decode_token(_mod, nil, _options), do: {:error, :invalid}
  def decode_token(mod, token_id, _options) do
    with {:ok, token} <- get_token_from_token_id(mod, token_id) do
      {:ok, token.claims}
    else
      _ -> {:error, :invalid}
    end
  end

  def token_to_token_id(token) do
    token.token <> Integer.to_string(token.id)
  end

  @doc """
  Split a token_id into the token_string & id
  Get the DB token (from the id)
  Perform a constant-time comparison with the token string
  """
  def get_token_from_token_id(mod, token_id) do
    try do
      <<token_string::bytes-size(64), id::binary>> = token_id

      with {:ok, token} <- apply(mod, :get_token, [id]) do
        # constant-time comparison
        if SecureCompare.compare(token.token, token_string) do
          {:ok, token}
        else
          {:error, :invalid}
        end
      else
        _ ->
          # Token not found in the database, slow the response slightly to mitigate token.id enumeration
          "v5AaBD39Wr+nZvqqjIyODZn2OcXIIOkLCZs35kS6p+OUR96McpwR1nBK3vn/SF6e"
          |> SecureCompare.compare(token_string)

          {:error, :invalid}
      end
    rescue
      _ ->
        # Poorly formatted token... I'm not sure how try / rescue impacts timing...
        "v5AaBD39Wr+nZvqqjIyODZn2OcXIIOkLCZs35kS6p+OUR96McpwR1nBK3vn/SF6e"
        |> SecureCompare.compare("XXXaBD39Wr+nZvqqjIyODZn2OcXIIOkLCZs35kS6p+OUR96McpwR1nBK3vn/SF6e")

        {:error, :invalid}
    end
  end

  @doc """
  Verifies the claims (not applicable but a required behaviour).
  """
  def verify_claims(_mod, claims, _options) do
    {:ok, claims}
  end

  @doc """
  Delete the token
  """
  def revoke(mod, claims, token_id, _options) do
    with {:ok, token} <- get_token_from_token_id(mod, token_id),
         {:ok, _token} <- apply(mod, :delete_token, [token.id]) do
      {:ok, claims}
    else
      _ -> {:error, :invalid}
    end
  end

  @doc """
  Refresh the token (not applicable but a required behaviour)

  It will return an error if called
  """
  def refresh(_mod, _old_token_id, _options) do
    {:error, :not_applicable}
  end

  @doc """
  Exchange a token of one type to another (not applicable but a required behaviour).

  It will return an error if called
  """
  def exchange(_mod, _old_token_id, _from_type, _to_type, _options) do
    {:error, :not_applicable}
  end
end
