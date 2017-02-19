defmodule Curator.Hooks do
  @moduledoc """
  This module hooks into the curator lifecycle.
  """

  defmacro __using__(_) do
    quote do
      @behaviour Curator.Hooks

      def before_sign_in(_, _), do: :ok
      def after_sign_in(conn, _, _), do: conn
      def after_failed_sign_in(conn, _, _), do: conn
      def after_extension(conn, _, _), do: conn

      defoverridable [
        {:before_sign_in, 2},
        {:after_sign_in, 3},
        {:after_failed_sign_in, 3},
        {:after_extension, 3}
      ]
    end
  end

  @callback before_sign_in(
    resource :: term,
    type :: atom
  ) :: :ok | {:error, atom | String.t}

  @callback after_sign_in(
    conn :: Plug.Conn.t,
    resource :: term,
    location :: atom
  ) :: Plug.Conn.t

  @callback after_failed_sign_in(
    conn :: Plug.Conn.t,
    resource :: term,
    location :: atom
  ) :: Plug.Conn.t

  @callback after_extension(
    conn :: Plug.Conn.t,
    type :: atom,
    resource :: term
  ) :: Plug.Conn.t
end

defmodule Curator.Hooks.Default do
  @moduledoc """
  Default implementation of GuardianHooks.
  """
  use Curator.Hooks
end
