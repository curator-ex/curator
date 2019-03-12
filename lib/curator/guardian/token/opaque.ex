defmodule Curator.Guardian.Token.Opaque do
  @moduledoc """
    Opaque token implementation for Guardian.

    Rather than the default JWT implementation, this module expects that a token
    will be an opaque string, that can be looked up (in a persistance module) to
    get the claims. It uses a subset of the standard JWT claims so it will function
    as a drop-in replacement for the default Guardian implementation.

    NOTE: To use this module, the guardian implementation module must
    implement get_token, create_token & delete_token (the
    Curator.Guardian.Token.Opaque.Persistence behaviour). An example can be found in
    the specs (it uses a context and an ecto repo). Redis, Genserver, or other
    stateful implementations can also be used to persist tokens.
   """

  @behaviour Guardian.Token

  @default_token_type "access"
  @default_ttl {0, :never}

  @token_length 64

  import Guardian, only: [stringify_keys: 1]

  @doc """
  Inspect the token without any validation.

  Return a map with keys: `claims`
  """
  def peek(_mod, nil), do: nil

  def peek(mod, token_id) do
    case decode_token(mod, token_id) do
      {:ok, claims} -> %{claims: claims}
      _ -> nil
    end
  end

  @doc """
  Generate a unique token

  NOTE: This is NOT the token_id, but a component used to build it
  (it will be combined with the DB id to create the token_id)
  """
  def token_id do
    @token_length
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64
    |> binary_part(0, @token_length)
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
      |> set_ttl(mod, options)

    {:ok, claims}
  end

  defp set_type(%{"typ" => typ} = claims, _mod, _opts) when not is_nil(typ), do: claims

  defp set_type(claims, mod, opts) do
    defaults = apply(mod, :default_token_type, [])
    typ = Keyword.get(opts, :token_type, defaults)
    Map.put(claims, "typ", to_string(typ || @default_token_type))
  end

  defp set_sub(claims, _mod, subject, _opts), do: Map.put(claims, "sub", subject)

  defp set_ttl(%{"exp" => exp} = claims, _mod, _opts) when not is_nil(exp), do: claims

  defp set_ttl(%{"typ" => token_typ} = claims, mod, opts) do
    ttl = Keyword.get(opts, :ttl)

    if ttl do
      set_ttl(claims, ttl)
    else
      token_typ = to_string(token_typ)
      token_ttl = apply(mod, :config, [:token_ttl, %{}])
      fallback_ttl = apply(mod, :config, [:ttl, @default_ttl])

      ttl = Map.get(token_ttl, token_typ, fallback_ttl)
      set_ttl(claims, ttl)
    end
  end

  defp set_ttl(the_claims, {num, period}) when is_binary(num),
    do: set_ttl(the_claims, {String.to_integer(num), period})

  defp set_ttl(the_claims, {num, period}) when is_binary(period),
    do: set_ttl(the_claims, {num, String.to_existing_atom(period)})

  defp set_ttl(the_claims, requested_ttl),
    do: assign_exp_from_ttl(the_claims, {Guardian.timestamp(), requested_ttl})

  defp assign_exp_from_ttl(the_claims, {_iat_v, {_, unit}}) when unit in [:never],
    do: the_claims

  defp assign_exp_from_ttl(the_claims, {iat_v, {seconds, unit}}) when unit in [:second, :seconds],
    do: Map.put(the_claims, "exp", iat_v + seconds)

  defp assign_exp_from_ttl(the_claims, {iat_v, {seconds, unit}}) when unit in [:second, :seconds],
    do: Map.put(the_claims, "exp", iat_v + seconds)

  defp assign_exp_from_ttl(the_claims, {iat_v, {minutes, unit}}) when unit in [:minute, :minutes],
    do: Map.put(the_claims, "exp", iat_v + minutes * 60)

  defp assign_exp_from_ttl(the_claims, {iat_v, {hours, unit}}) when unit in [:hour, :hours],
    do: Map.put(the_claims, "exp", iat_v + hours * 60 * 60)

  defp assign_exp_from_ttl(the_claims, {iat_v, {days, unit}}) when unit in [:day, :days],
    do: Map.put(the_claims, "exp", iat_v + days * 24 * 60 * 60)

  defp assign_exp_from_ttl(the_claims, {iat_v, {weeks, unit}}) when unit in [:week, :weeks],
    do: Map.put(the_claims, "exp", iat_v + weeks * 7 * 24 * 60 * 60)

  defp assign_exp_from_ttl(_, {_iat_v, {_, units}}), do: raise("Unknown Units: #{units}")

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

  @doc """
  Turn a token into a token_id

  A token_id is just the token.token + the token.id (concatenated)
  The id is used for a quick DB lookup, the token is then compared in constant time.
  This approach contrasts looking up the token in the DB by using token. That could
  leak info in a timing attack
  """
  def token_to_token_id(token) do
    "#{token.token}#{token.id}"
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
  Verifies the claims (only checks exp).
  """
  def verify_claims(mod, claims, opts) do
    Enum.reduce(claims, {:ok, claims}, fn
      {k, _v}, {:ok, claims} -> verify_claim(mod, k, claims, opts)
      _, {:error, _reason} = err -> err
    end)
  end

  def verify_claim(_mod, "exp", %{"exp" => nil} = claims, _opts), do: {:ok, claims}

  def verify_claim(_mod, "exp", %{"exp" => exp} = claims, _opts) do
    if exp >= Guardian.timestamp() do
      {:ok, claims}
    else
      {:error, :token_expired}
    end
  end

  def verify_claim(_mod, _claim_key, claims, _opts), do: {:ok, claims}

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
