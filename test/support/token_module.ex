defmodule Curator.Support.TokenModule do
  @moduledoc """
  A simple json encoding of tokens for testing purposes

  This was taken from Guardian.Support.TokenModule, but the package does not include test files
  """
  @behaviour Guardian.Token

  def token_id do
    Ecto.UUID.generate()
  end

  def peek(_mod, token) do
    claims =
      token
      |> Base.decode64!()
      |> Poison.decode!()
      |> Map.get("claims")

    %{claims: claims}
  end

  def build_claims(mod, _resource, sub, claims, opts) do
    default_token_type = apply(mod, :default_token_type, [])
    token_type = Keyword.get(opts, :token_type, default_token_type)

    claims =
      claims
      |> Map.put("sub", sub)
      |> Map.put("typ", token_type)

    if Keyword.get(opts, :fail_build_claims) do
      {:error, Keyword.get(opts, :fail_build_claims)}
    else
      {:ok, claims}
    end
  end

  def create_token(_mod, claims, opts) do
    if Keyword.get(opts, :fail_create_token) do
      {:error, Keyword.get(opts, :fail_create_token)}
    else
      token =
        %{"claims" => claims}
        |> Poison.encode!()
        |> Base.url_encode64()

      {:ok, token}
    end
  end

  def decode_token(_mod, token, opts) do
    if Keyword.get(opts, :fail_decode_token) do
      {:error, Keyword.get(opts, :fail_decode_token)}
    else
      try do
        claims =
          token
          |> Base.decode64!()
          |> Poison.decode!()
          |> Map.get("claims")

        {:ok, claims}
      rescue
        _ -> {:error, :invalid_token}
      end
    end
  end

  def verify_claims(_mod, claims, opts) do
    if Keyword.get(opts, :fail_verify_claims) do
      {:error, Keyword.get(opts, :fail_verify_claims)}
    else
      {:ok, claims}
    end
  end

  def revoke(_mod, claims, _token, opts) do
    if Keyword.get(opts, :fail_revoke) do
      {:error, Keyword.get(opts, :fail_revoke)}
    else
      {:ok, claims}
    end
  end

  def refresh(mod, old_token, opts) do
    if Keyword.get(opts, :fail_refresh) do
      {:error, Keyword.get(opts, :fail_refresh)}
    else
      {:ok, old_claims} = decode_token(mod, old_token, opts)
      resp = {old_token, old_claims}
      {:ok, resp, resp}
    end
  end

  def exchange(mod, old_token, _from_type, to_type, opts) do
    if Keyword.get(opts, :fail_exchange) do
      {:error, Keyword.get(opts, :fail_exchange)}
    else
      {:ok, old_claims} = decode_token(mod, old_token, opts)
      new_c = Map.put(old_claims, "typ", to_type)
      new_t = Poison.encode!(%{"claims" => new_c})
      {:ok, {old_token, old_claims}, {new_t, new_c}}
    end
  end
end
