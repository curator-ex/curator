defmodule Curator.Guardian.Token.Opaque.Persistence do
  @moduledoc """
  The opaque token can be stored in _many_ different backends.
  This is the behaviour those backends must implement
  """

  @type token_id :: String.t()
  @type token :: any
  @type claims :: Map.t()

  @doc """
  Get a Token
  """
  @callback get_token(token_id) ::
              {:ok, token} | {:error, any}

  @doc """
  Create a token
  """
  @callback create_token(claims) ::
              {:ok, token} | {:error, any}

  @doc """
  Delete a token
  """
  @callback delete_token(token_id) ::
              {:ok, token} | {:error, any}
end
