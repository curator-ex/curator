defmodule Curator.ViewHelpers do
  @moduledoc """
  A helper for views & templates to interact with Curator.
  """

  @doc """
  Ease-of-access method for fetching the currently authenticated resource
  """
  @spec current_user(Plug.Conn.t) :: any | nil
  def current_user(conn) do
    case Curator.PlugHelper.current_resource(conn) do
      {:ok, resource} -> resource
      {:error, _error} -> nil
      nil -> nil
    end
  end
end

