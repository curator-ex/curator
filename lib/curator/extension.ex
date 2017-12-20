defmodule Curator.Extension do
  defmacro __using__(opts \\ []) do
    mod = Keyword.get(opts, :mod, Curator.Extension)

    quote do
      @behaviour Curator.Extension

      def unauthenticated_plugs(), do: apply(unquote(mod), :unauthenticated_plugs, [])
      def authenticated_plugs(), do: apply(unquote(mod), :authenticated_plugs, [])
      def unauthenticated_routes(), do: apply(unquote(mod), :unauthenticated_routes, [])
      def authenticated_routes(), do: apply(unquote(mod), :authenticated_routes, [])

      def before_sign_in(user, opts \\ []), do: apply(unquote(mod), :before_sign_in, [user, opts])
      def after_sign_in(conn, user, opts \\ []), do: apply(unquote(mod), :after_sign_in, [conn, user, opts])

      defoverridable unauthenticated_plugs: 0,
                     authenticated_plugs: 0,
                     unauthenticated_routes: 0,
                     authenticated_routes: 0,
                     before_sign_in: 2,
                     after_sign_in: 3
    end
  end

  @type options :: Keyword.t()
  # @type conditional_tuple :: {:ok, any} | {:error, any}

  @callback unauthenticated_plugs() :: nil
  @callback authenticated_plugs() :: nil
  @callback unauthenticated_routes() :: nil
  @callback authenticated_routes() :: nil

  @callback before_sign_in(
              resource :: any,
              options :: options
            ) :: :ok | {:error, atom}

  @callback after_sign_in(
              conn :: Plug.Conn.t(),
              resource :: any,
              options :: options
            ) :: Plug.Conn.t()

  def before_sign_in(user, opts \\ []), do: :ok
  def after_sign_in(conn, user, opts \\ []), do: conn

  def unauthenticated_plugs(), do: nil
  def authenticated_plugs(), do: nil
  def unauthenticated_routes(), do: nil
  def authenticated_routes(), do: nil
end
