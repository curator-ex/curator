defmodule Curator.PlugHelper do
  @moduledoc """
  A helper for Plugs to interact with Curator. This will act as an adapter
  between the curator modules and the configured session_handler.
  """

  @default_key :default

  import Curator.Keys
  alias Curator.Config

  @doc """
  Fetch the currently authenticated resource if loaded, optionally located at
  a location (key)
  """
  @spec current_resource(Plug.Conn.t, atom) :: any | nil
  def current_resource(conn, the_key \\ @default_key) do
    Config.session_handler.current_resource(conn, the_key)
  end

  @doc """
  set the authenticated resource, optionally located at a location (key)
  """
  @spec set_current_resource(Plug.Conn.t, any, atom) :: Plug.Conn.t
  def set_current_resource(conn, resource, the_key \\ @default_key) do
    Config.session_handler.set_current_resource(conn, resource, the_key)
  end

  @doc """
  Clears the authenticated resource.
  This will also set an error and delete the session.
  """
  @spec clear_current_resource_with_error(Plug.Conn.t, any, atom) :: Plug.Conn.t
  def clear_current_resource_with_error(conn, error, the_key \\ @default_key) do
    Config.session_handler.clear_current_resource_with_error(conn, error, the_key)
  end

  @doc """
  Sign in a resource (that your configured serializer knows about)
  into the current web session.
  """
  @spec sign_in(Plug.Conn.t, any) :: Plug.Conn.t
  def sign_in(conn, object) do
    Config.session_handler.sign_in(conn, object)
  end

  @doc """
  Sign out of a session.

  If no key is specified, the entire session is cleared.  Otherwise, only the
  location specified is cleared
  """
  @spec sign_out(Plug.Conn.t) :: Plug.Conn.t
  def sign_out(conn, the_key \\ :all) do
    Config.session_handler.sign_out(conn, the_key)
  end
end
