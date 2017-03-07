defmodule Curator.SessionHandlers.Guardian do
  @behaviour Curator.SessionHandler

  @default_key :default

  import Curator.Keys

  # TODO: Just delegate everything...
  # import Guardian.Plug

  @spec current_resource(Plug.Conn.t, atom) :: any | nil
  def current_resource(conn, the_key \\ @default_key) do
    Guardian.Plug.current_resource(conn, the_key)
  end

  @spec set_current_resource(Plug.Conn.t, any, atom) :: Plug.Conn.t
  def set_current_resource(conn, resource, the_key \\ @default_key) do
    Guardian.Plug.set_current_resource(conn, resource, the_key)
  end

  @spec clear_current_resource_with_error(Plug.Conn.t, any, atom) :: Plug.Conn.t
  def clear_current_resource_with_error(conn, error, the_key \\ @default_key) do
    conn
    |> Plug.Conn.delete_session(base_key(the_key))
    |> Guardian.Plug.set_claims({:error, error}, the_key)
    |> Guardian.Plug.set_current_resource(nil, the_key)
  end

  @spec sign_in(Plug.Conn.t, any) :: Plug.Conn.t
  def sign_in(conn, object) do
    Guardian.Plug.sign_in(conn, object)
  end

  @spec sign_out(Plug.Conn.t) :: Plug.Conn.t
  def sign_out(conn, the_key \\ :all) do
    Guardian.Plug.sign_out(conn, the_key)
  end
end

defmodule Curator.SessionHandlers.Guardian.LoadSession do
  use Plug.Builder

  plug Guardian.Plug.VerifySession
  plug Guardian.Plug.LoadResource
end

defmodule Curator.SessionHandlers.Guardian.EnsureAuthenticated do
  def init(opts) do
    Guardian.Plug.EnsureAuthenticated.init(opts)
  end

  def call(conn, opts) do
    Guardian.Plug.EnsureAuthenticated.call(conn, opts)
  end
end

defmodule Curator.SessionHandlers.Guardian.EnsureNotAuthenticated do
  def init(opts) do
    Guardian.Plug.EnsureNotAuthenticated.init(opts)
  end

  def call(conn, opts) do
    Guardian.Plug.EnsureNotAuthenticated.call(conn, opts)
  end
end
