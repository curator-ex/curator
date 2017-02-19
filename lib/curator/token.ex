defmodule Curator.Token do
  @moduledoc """
  A Curator Helper module to Generate random 64 byte tokens. They are useful as
  one-time token to be stored in the db.
  e.g. password_reset_token, confirmation_token...
  """

  def generate do
    random_string(64)
  end

  defp random_string(length) do
    length
    |> :crypto.strong_rand_bytes
    |> Base.url_encode64
    |> binary_part(0, length)
  end
end
