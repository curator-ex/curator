defmodule <%= inspect context.web_module %>.Auth.CuratorHelper do
  @moduledoc """
  A helper for views & templates to interact with Curator.
  """

  @doc """
  Ease-of-access method for fetching the currently authenticated resource
  """
  @spec current_user(Plug.Conn.t) :: any | nil
  def current_user(conn) do
    <%= inspect context.web_module %>.Auth.Curator.current_resource(conn)
  end
end
