defmodule Curator.Extension do
  defmacro __using__(_opts \\ []) do
    quote do
      @behaviour Curator.Extension

      def active_for_authentication?(mod, user), do: :ok

      def after_sign_in(_mod, conn, _user, _opts), do: conn

      def unauthenticated_routes(_mod), do: nil
      def authenticated_routes(_mod), do: nil

      # Config
      defp curator(mod) do
        mod.config(:curator, {Curator.Config, :config_error, ["curator"]})
      end

      defp opaque_guardian(mod) do
        curator(mod).config(:opaque_guardian, {Curator.Config, :config_error, ["opaque_guardian"]})
      end

      defp user(mod) do
        curator(mod).config(:user, {Curator.Config, :config_error, ["user"]})
      end

      defp repo(mod) do
        curator(mod).config(:repo, {Curator.Config, :config_error, ["repo"]})
      end

      defoverridable active_for_authentication?: 2,
                     after_sign_in: 4,
                     unauthenticated_routes: 1,
                     authenticated_routes: 1

    end
  end

  @type options :: Keyword.t()

  @callback active_for_authentication?(
              module,
              any
            ) :: :ok | {:error, atom}

  @callback after_sign_in(
              module,
              Plug.Conn.t(),
              any,
              options
            ) :: Plug.Conn.t()

  @callback unauthenticated_routes(module) :: nil
  @callback authenticated_routes(module) :: nil
end
