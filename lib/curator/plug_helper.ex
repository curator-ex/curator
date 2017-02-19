defmodule Curator.PlugHelper do
  @moduledoc """
  A helper for Plugs to interact with Curator. This will act as an adapter
  between the curator modules and the configured session_handler.

  Right now it only uses Guardian, but that should change...

  """

  @default_key :default

  import Curator.Keys

  @doc """
  Fetch the currently authenticated resource if loaded, optionally located at
  a location (key)
  """
  @spec current_resource(Plug.Conn.t, atom) :: any | nil
  def current_resource(conn, the_key \\ @default_key) do
    # conn.private[resource_key(the_key)]

    Guardian.Plug.current_resource(conn, the_key)
  end

  @doc """
  set the authenticated resource, optionally located at a location (key)
  """
  @spec set_current_resource(Plug.Conn.t, any, atom) :: Plug.Conn.t
  def set_current_resource(conn, resource, the_key \\ @default_key) do
    # Plug.Conn.put_private(conn, resource_key(the_key), resource)

    Guardian.Plug.set_current_resource(conn, resource, the_key)
  end

  @doc """
  Clears the authenticated resource.
  This will also set an error and delete the session.
  """
  @spec clear_current_resource_with_error(Plug.Conn.t, any, atom) :: Plug.Conn.t
  def clear_current_resource_with_error(conn, error, the_key \\ @default_key) do
    conn
    |> Plug.Conn.delete_session(base_key(the_key))
    |> Guardian.Plug.set_claims({:error, error}, the_key)
    |> Guardian.Plug.set_current_resource(nil, the_key)
  end
end
