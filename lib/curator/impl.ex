defmodule Curator.Impl do
  defmacro __using__(opts \\ []) do
    mod = Keyword.fetch!(opts, :mod)

    quote do
      @behaviour Curator.Impl

      def active_for_authentication?(user),
        do: apply(unquote(mod), :active_for_authentication?, [__MODULE__, user])

      def after_sign_in(conn, user, opts \\ [])

      def after_sign_in(conn, user, opts),
        do: apply(unquote(mod), :after_sign_in, [__MODULE__, conn, user, opts])

      def unauthenticated_routes(), do: apply(unquote(mod), :unauthenticated_routes, [__MODULE__])
      def authenticated_routes(), do: apply(unquote(mod), :authenticated_routes, [__MODULE__])

      defoverridable active_for_authentication?: 1,
                     after_sign_in: 3,
                     unauthenticated_routes: 0,
                     authenticated_routes: 0
    end
  end

  @type options :: Keyword.t()

  @callback active_for_authentication?(any) :: :ok | {:error, atom}

  @callback after_sign_in(
              Plug.Conn.t(),
              any,
              options
            ) :: Plug.Conn.t()

  @callback unauthenticated_routes() :: nil
  @callback authenticated_routes() :: nil
end
