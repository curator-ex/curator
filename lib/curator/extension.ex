defmodule Curator.Extension do
  defmacro __using__(opts \\ []) do
    mod = Keyword.get(opts, :mod, Curator.Extension)

    quote do
      @behaviour Curator.Extension

      def unauthenticated_routes(), do: apply(unquote(mod), :unauthenticated_routes, [])
      def authenticated_routes(), do: apply(unquote(mod), :authenticated_routes, [])

      def before_sign_in(user, opts \\ [])
      def before_sign_in(user, opts), do: apply(unquote(mod), :before_sign_in, [user, opts])

      def after_sign_in(conn, user, opts \\ [])
      def after_sign_in(conn, user, opts), do: apply(unquote(mod), :after_sign_in, [conn, user, opts])

      def curator_schema(), do: apply(unquote(mod), :curator_schema, [])
      def curator_fields(), do: apply(unquote(mod), :curator_fields, [])
      def curator_validation(changeset), do: apply(unquote(mod), :curator_validation, [changeset])

      defoverridable unauthenticated_routes: 0,
                     authenticated_routes: 0,
                     before_sign_in: 2,
                     after_sign_in: 3,
                     curator_schema: 0,
                     curator_fields: 0,
                     curator_validation: 1
    end
  end

  @type options :: Keyword.t()
  # @type conditional_tuple :: {:ok, any} | {:error, any}

  @callback before_sign_in(
              resource :: any,
              options :: options
            ) :: :ok | {:error, atom}

  @callback after_sign_in(
              conn :: Plug.Conn.t(),
              resource :: any,
              options :: options
            ) :: Plug.Conn.t()

  @callback unauthenticated_routes() :: nil
  @callback authenticated_routes() :: nil

  def before_sign_in(_user, _opts), do: :ok
  def after_sign_in(conn, _user, _opts), do: conn

  def unauthenticated_routes(), do: nil
  def authenticated_routes(), do: nil

  def curator_schema(), do: nil
  def curator_fields(), do: []
  def curator_validation(changeset), do: changeset
end
