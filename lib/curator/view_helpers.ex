defmodule Curator.ViewHelpers do
  @moduledoc """
  A helper for views & templates to interact with Curator. 
  """

  @doc """
  Ease-of-access method for fetching the currently authenticated resource
  """
  @spec current_resource(Plug.Conn.t) :: any | nil
  def current_resource(conn) do
    Curator.PlugHelper.current_resource(conn)
  end
end

