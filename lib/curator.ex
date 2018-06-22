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

      # Registered Extensions
      def before_sign_in(resource, opts \\ [])
      def before_sign_in(resource, opts),
        do: Curator.before_sign_in(__MODULE__, resource, opts)

      def after_sign_in(conn, resource, opts \\ [])
      def after_sign_in(conn, resource, opts),
        do: Curator.after_sign_in(__MODULE__, conn, resource, opts)

      # TODO
      # def after_failed_sign_in(conn, resource, opts \\ [])

      def extension(fun, args),
        do: Curator.extension(__MODULE__, fun, args)

      def changeset(fun, changeset, attrs),
        do: Curator.changeset(__MODULE__, fun, changeset, attrs)

      # Delegate to Guardian
      def sign_in(conn, resource, opts \\ []),
        do: Curator.sign_in(__MODULE__, conn, resource, opts)

      def sign_out(conn, opts \\ []),
        do: Curator.sign_out(__MODULE__, conn, opts)

      def current_resource(conn, opts \\ []),
        do: Curator.current_resource(__MODULE__, conn, opts)

      # def modules() do
      #   @config_with_key_and_default :module, []
      # end

      defoverridable before_sign_in: 2,
                     after_sign_in: 3

    end
  end

  # Extensions

  @doc """
  apply before_sign_in to each module (until one fails)
  """
  def before_sign_in(mod, resource, opts) do
    modules = modules(mod)

    Enum.reduce_while(modules, :ok, fn (module, :ok) ->
      case apply(module, :before_sign_in, [resource, opts]) do
        :ok -> {:cont, :ok}
        {:error, error} -> {:halt, {:error, error}}
      end
    end)
  end

  @doc """
  apply after_sign_in to _all_ modules
  """
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

  @doc """
  Call an extension on all modules

  This provides a way to coordinate actions between the modules, without them knowing about eachother directly.
  Each module can have verious extensions it broadcasts. The other modules decide if they'll listen...
  """
  def extension(mod, fun, args) do
    modules = modules(mod)

    Enum.each(modules, fn(module) ->
      arity = Enum.count(args)

      if function_exported?(module, fun, arity) do
        apply(module, fun, args)
      end
    end)
  end

  @doc """
  Call a changeset on all modules

  Similar to an extension, this accumulates a changeset across various implementations
  """
  def changeset(mod, fun, changeset, attrs) do
    modules = modules(mod)

    Enum.reduce(modules, changeset, fn (module, changeset) ->
      if function_exported?(module, fun, 2) do
        apply(module, fun, [changeset, attrs])
      else
        changeset
      end
    end)
  end

  # Delegate to Guardian
  def sign_in(mod, conn, resource, opts) do
    Module.concat(guardian_module(mod), Plug).sign_in(conn, resource, opts)
  end

  def sign_out(mod, conn, opts) do
    Module.concat(guardian_module(mod), Plug).sign_out(conn, opts)
  end

  def current_resource(mod, conn, opts) do
    Module.concat(guardian_module(mod), Plug).current_resource(conn, opts)
  end

  def guardian_module(mod) do
    mod.config(:guardian)
  end

  def modules(mod) do
    mod.config(:modules)
  end

  def repo(mod) do
    mod.config(:repo)
  end

  def user(mod) do
    mod.config(:user)
  end
end
