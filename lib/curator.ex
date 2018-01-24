defmodule Curator do
  @type options :: Keyword.t()

  @callback before_sign_in(
              resource :: any,
              options :: options
            ) :: :ok | {:error, atom}

  @callback after_sign_in(
              conn :: Plug.Conn.t(),
              resource :: any,
              options :: options
            ) :: Plug.Conn.t()

  defmacro __using__(opts \\ []) do
    quote do
      use Curator.Config, unquote(opts)
      @behaviour Curator

      def before_sign_in(resource, opts \\ []),
        do: Curator.before_sign_in(__MODULE__, resource, opts)

      def after_sign_in(conn, resource, opts \\ []),
        do: Curator.after_sign_in(__MODULE__, conn, resource, opts)

      def sign_in(conn, resource, opts \\ []),
        do: Curator.sign_in(__MODULE__, conn, resource, opts)

      def sign_out(conn, opts \\ []),
        do: Curator.sign_out(__MODULE__, conn, opts)

      def current_resource(conn, opts \\ []),
        do: Curator.current_resource(__MODULE__, conn, opts)

      # def after_failed_sign_in(conn, resource, opts \\ [])
      # def after_extension(conn, type, resource, opts \\ [])

      defoverridable before_sign_in: 2,
                     after_sign_in: 3,
                     sign_in: 3,
                     sign_out: 2,
                     current_resource: 2
    end
  end

  def before_sign_in(mod, resource, opts) do
    modules = modules(mod)

    Enum.reduce_while(modules, :ok, fn (module, :ok) ->
      case apply(module, :before_sign_in, [resource, opts]) do
        :ok -> {:cont, :ok}
        {:error, error} -> {:halt, {:error, error}}
      end
    end)
  end

  def after_sign_in(mod, conn, resource, opts) do
    modules = modules(mod)

    Enum.reduce(modules, conn, fn (module, conn) ->
      apply(module, :after_sign_in, [conn, resource, opts])
    end)

    # Enum.reduce_while(modules, {:ok, conn}, fn (module) ->
    #   case apply(module, :after_sign_in, [resource, opts]) do
    #     {:ok, conn} -> {:cont, {:ok, conn}}
    #     {:error, error} -> {:halt, {:error, error}}
    #   end
    # end)
  end

  def sign_in(mod, conn, resource, opts) do
    guardian_module = apply(mod, :config, [:guardian, []])
    Module.concat(guardian_module, Plug).sign_in(conn, resource)
  end

  def sign_out(mod, conn, opts) do
    guardian_module = apply(mod, :config, [:guardian, []])
    Module.concat(guardian_module, Plug).sign_out(conn)
  end

  def current_resource(mod, conn, opts) do
    guardian_module = apply(mod, :config, [:guardian, []])
    Module.concat(guardian_module, Plug).current_resource(conn)
  end

  def modules(mod) do
    apply(mod, :config, [:modules, []])
  end
end
