defmodule Curator.SessionHandlers.Simple do
  @behaviour Curator.SessionHandler

  @default_key :default

  import Curator.Keys

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
    # |> TODO
  end

  @doc """
  Fetch the claims for the current request
  """
  @spec claims(Plug.Conn.t, atom) :: {:ok, map} | {:error, atom | String.t}
  def claims(conn, the_key \\ @default_key) do
    case conn.private[claims_key(the_key)] do
      {:ok, the_claims} -> {:ok, the_claims}
      {:error, reason} -> {:error, reason}
      _ -> {:error, :no_session}
    end
  end

  @spec set_claims(Plug.Conn.t, nil | {:ok, map} | {:error, String.t}, atom) :: Plug.Conn.t
  def set_claims(conn, new_claims, the_key \\ @default_key) do
    Plug.Conn.put_private(conn, claims_key(the_key), new_claims)
  end

  @spec sign_in(Plug.Conn.t, any) :: Plug.Conn.t
  def sign_in(conn, object) do
    # TODO
  end

  @spec sign_out(Plug.Conn.t) :: Plug.Conn.t
  def sign_out(conn, the_key \\ :all) do
    # TODO
  end
end

defmodule Curator.SessionHandlers.Simple.LoadSession do
  import Plug.Conn

  @default_key :default

  import Curator.Keys

  def init(opts) do
    opts
  end

  def call(conn, opts) do
    key = Map.get(opts, :key, @default_key)

    case Curator.SessionHandlers.Simple.claims(conn, key) do
      {:ok, _} -> conn
      {:error, _} ->
        claims = Plug.Conn.get_session(conn, base_key(key))

        if claims do
          conn
          |> Curator.SessionHandlers.Simple.set_claims({:ok, claims}, key)

          case Curator.SessionHandlers.Simple.current_resource(conn, key) do
            nil ->
              claims
              |> load_resource(opts)
              |> put_current_resource(conn, key)
            _ -> conn
          end
        else
          conn
        end
    end
  end

  defp put_current_resource({:ok, resource}, conn, key) do
    Curator.SessionHandlers.Simple.set_current_resource(conn, resource, key)
  end

  defp put_current_resource({:error, _}, conn, key) do
    Curator.SessionHandlers.Simple.set_current_resource(conn, nil, key)
  end

  defp load_resource(claims, opts) do
    serializer = get_serializer(opts)

    claims
    |> Map.get("sub")
    |> serializer.from_token
  end

  defp get_serializer(opts) do
    Map.get(opts, :serializer, Curator.UserSerializer)
  end
end

defmodule Curator.SessionHandlers.Simple.EnsureAuthenticated do
  import Plug.Conn

  @default_key :default

  import Curator.Keys

  def init(opts) do
    opts
  end

  def call(conn, opts) do
    raise "TODO"
  end
end

defmodule Curator.SessionHandlers.Simple.EnsureNotAuthenticated do
  import Plug.Conn

    @default_key :default

    import Curator.Keys

    def init(opts) do
      opts
    end

    def call(conn, opts) do
      raise "TODO"
    end
end
