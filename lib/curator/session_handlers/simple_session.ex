defmodule Curator.SessionHandlers.SimpleSession do
  @behaviour Curator.SessionHandler

  @default_key :default

  import Curator.Keys
  import Plug.Conn

  @spec current_resource(Plug.Conn.t, atom) :: any | nil
  def current_resource(conn, the_key \\ @default_key) do
    conn.private[resource_key(the_key)]
  end

  @spec set_current_resource(Plug.Conn.t, any, atom) :: Plug.Conn.t
  def set_current_resource(conn, resource, the_key \\ @default_key) do
    Plug.Conn.put_private(conn, resource_key(the_key), resource)
  end

  @spec clear_current_resource_with_error(Plug.Conn.t, any, atom) :: Plug.Conn.t
  def clear_current_resource_with_error(conn, error, the_key \\ @default_key) do
    conn
    |> Plug.Conn.delete_session(base_key(the_key))
  end

  @doc """
  Fetch the claims for the current request
  """
  @spec claims(Plug.Conn.t, atom) :: {:ok, map} | {:error, atom | String.t}
  def claims(conn, the_key \\ @default_key) do
    {:error, "NOT USED"}
  end

  @spec set_claims(Plug.Conn.t, nil | {:ok, map} | {:error, String.t}, atom) :: Plug.Conn.t
  def set_claims(conn, claims, the_key \\ @default_key) do
    {:error, "NOT USED"}
  end

  @spec sign_in(Plug.Conn.t, any) :: Plug.Conn.t
  def sign_in(conn, object, the_key \\ @default_key) do
    resource_id = object.id
    conn
    |> Plug.Conn.put_session(token_key(the_key), resource_id)
    |> configure_session(renew: true)
  end

  @spec sign_out(Plug.Conn.t) :: Plug.Conn.t
  def sign_out(conn, the_key \\ @default_key)
  def sign_out(conn, :all) do
    conn
    |> configure_session(drop: true)
  end

  def sign_out(conn, the_key) do
    conn
    |> delete_session(token_key(the_key))
  end
end

defmodule Curator.SessionHandlers.SimpleSession.LoadSession do
  import Plug.Conn
  alias Curator.Config

  @default_key :default

  import Curator.Keys

  alias Curator.SessionHandlers.SimpleSession

  def init(opts) do
    opts
  end

  def call(conn, opts) do
    key = Keyword.get(opts, :key, @default_key)

    case get_session(conn, token_key(key)) do
      nil -> conn
      id ->
        resource = load_resource(id)
        SimpleSession.set_current_resource(conn, {:ok, resource}, key)
    end
  end

  def load_resource(id) do
    Config.context.get_user!(id)
  end
end

defmodule Curator.SessionHandlers.SimpleSession.EnsureResourceAndSession do
  import Plug.Conn
  alias Curator.Config

  @default_key :default

  import Curator.Keys

  alias Curator.SessionHandlers.SimpleSession

  def init(opts) do
    opts
  end

  def call(conn, opts) do
    key = Keyword.get(opts, :key, @default_key)

    case SimpleSession.current_resource(conn, key) do
      nil -> apply(Config.error_handler(), :auth_error, [conn, {:no_session, :no_session}, opts])
      {:error, error} -> apply(Config.error_handler(), :auth_error, [conn, {:error, error}, opts])
      {:ok, _resource} -> conn
    end
  end
end

defmodule Curator.SessionHandlers.SimpleSession.EnsureResourceOrNoSession do
  import Plug.Conn
  alias Curator.Config

  @default_key :default

  import Curator.Keys

  alias Curator.SessionHandlers.SimpleSession

  def init(opts) do
    opts
  end

  def call(conn, opts) do
    key = Keyword.get(opts, :key, @default_key)

    case SimpleSession.current_resource(conn, key) do
      {:ok, _resource} -> conn
      {:error, error} -> apply(Config.error_handler(), :auth_error, [conn, {:error, error}, opts])
      nil ->
        case get_session(conn, token_key(key)) do
          nil -> conn
          _id -> apply(Config.error_handler(), :auth_error, [conn, {:no_session, :no_session}, opts])
        end
    end
  end
end
