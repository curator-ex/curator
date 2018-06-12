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

  import Guardian, only: [stringify_keys: 1]

  @doc """
  Inspect the token.

  Return a map with keys: `claims`
  """
  def peek(_mod, nil), do: nil

  def peek(mod, token_id) do
    case apply(mod, :get_token, [token_id]) do
      {:ok, token} -> %{claims: token.claims}
      _ -> nil
    end
  end

  @doc """
  Generate unique token id
  """
  def token_id do
    length = 64
    :crypto.strong_rand_bytes(length) |> Base.encode64 |> binary_part(0, length)
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
  Returns the token

  """
  def create_token(mod, claims, _options \\ []) do
    case apply(mod, :create_token, [claims]) do
      {:ok, token} ->
        {:ok, token}
      result ->
        result
    end
  end

  @doc """
  Find the token and return its claims (or return an error)
  """
  def decode_token(mod, token_id, _options \\ []) do
    case apply(mod, :get_token, [token_id]) do
      {:ok, token} -> {:ok, token.claims}
      result -> result
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
    case apply(mod, :delete_token, [token_id]) do
      {:ok, _} ->
        {:ok, claims}
      result -> result
    end
  end

  @doc """
  Refresh the token (not applicable but a required behaviour)

  It will return an error if called
  """
  def refresh(_mod, _old_token, _options) do
    {:error, :not_applicable}
  end

  @doc """
  Exchange a token of one type to another (not applicable but a required behaviour).

  It will return an error if called
  """
  def exchange(_mod, _old_token, _from_type, _to_type, _options) do
    {:error, :not_applicable}
  end
end
