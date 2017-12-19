defmodule Curator.Extension do
  defmacro __using__(_) do
    quote do
      @behaviour Curator.Extension

      use Curator.Hooks

      def unauthenticated_plugs(), do: nil
      def authenticated_plugs(), do: nil
      def unauthenticated_routes(), do: nil
      def authenticated_routes(), do: nil

      # def before_sign_in(_, _), do: :ok
      # def after_sign_in(conn, _, _), do: conn
      # def after_failed_sign_in(conn, _, _), do: conn
      # def after_extension(conn, _, _), do: conn

      defoverridable [
        {:unauthenticated_plugs, 0},
        {:authenticated_plugs, 0},
        {:unauthenticated_routes, 0},
        {:authenticated_routes, 0}
      ]
    end
  end

  @callback unauthenticated_plugs() :: nil
  @callback authenticated_plugs() :: nil
  @callback unauthenticated_routes() :: nil
  @callback authenticated_routes() :: nil

  # @callback before_sign_in(
  #   resource :: term,
  #   type :: atom
  # ) :: :ok | {:error, atom | String.t}

  # @callback after_sign_in(
  #   conn :: Plug.Conn.t,
  #   resource :: term,
  #   location :: atom
  # ) :: Plug.Conn.t

  # @callback after_failed_sign_in(
  #   conn :: Plug.Conn.t,
  #   resource :: term,
  #   location :: atom
  # ) :: Plug.Conn.t

  # @callback after_extension(
  #   conn :: Plug.Conn.t,
  #   type :: atom,
  #   resource :: term
  # ) :: Plug.Conn.t
end
