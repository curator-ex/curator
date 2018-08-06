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

      def extension_reduce_while(fun, args),
        do: Curator.extension_reduce_while(__MODULE__, fun, args)

      def changeset(fun, changeset, attrs),
        do: Curator.changeset(__MODULE__, fun, changeset, attrs)

      def deliver_email(fun, args),
        do: Curator.deliver_email(__MODULE__, fun, args)

      # Delegate to Guardian
      def sign_in(conn, resource, opts \\ []),
        do: Curator.sign_in(__MODULE__, conn, resource, opts)

      def sign_out(conn, opts \\ []),
        do: Curator.sign_out(__MODULE__, conn, opts)

      def current_resource(conn, opts \\ []),
        do: Curator.current_resource(__MODULE__, conn, opts)

      # Routing
      def store_return_to_url(conn),
        do: Curator.store_return_to_url(__MODULE__, conn)

      def redirect_after_sign_in(conn),
        do: Curator.redirect_after_sign_in(__MODULE__, conn)

      # def modules() do
      #   @config_with_key_and_default :module, []
      # end

      def find_user_by_email(email) do
        Curator.find_user_by_email(__MODULE__, email)
      end

      defoverridable before_sign_in: 2,
                     after_sign_in: 3,
                     redirect_after_sign_in: 1,
                     find_user_by_email: 1

    end
  end

  # Extensions

  @doc """
  apply before_sign_in to each module (until one fails)
  """
  # def before_sign_in(mod, resource, opts) do
  #   modules = modules(mod)
  #
  #   Enum.reduce_while(modules, :ok, fn (module, :ok) ->
  #     case apply(module, :before_sign_in, [resource, opts]) do
  #       :ok -> {:cont, :ok}
  #       {:error, error} -> {:halt, {:error, error}}
  #     end
  #   end)
  # end

  def before_sign_in(mod, resource, opts) do
    extension_reduce_while(mod, :before_sign_in, [resource, opts])
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

  def store_return_to_url(_mod, conn) do
    url = case conn.query_string do
            "" -> conn.request_path
            _ -> conn.request_path <> "?" <> conn.query_string
          end

    Plug.Conn.put_session(conn, "user_return_to",  url)
  end

  def redirect_after_sign_in(_mod, conn) do
    url = case Plug.Conn.get_session(conn, "user_return_to") do
      nil -> "/"
      value -> value
    end

    conn
    |> Plug.Conn.put_session("user_return_to", nil)
    |> Phoenix.Controller.redirect(to: url)
  end

  @doc """
  Call an extension on all modules

  This provides a way to coordinate actions between the modules, without them knowing about eachother directly.
  Each module can have verious extensions it broadcasts. The other modules decide if they'll listen...
  """
  def extension(mod, fun, args) do
    modules = modules(mod)
    arity = Enum.count(args)

    Enum.each(modules, fn(module) ->
      if function_exported?(module, fun, arity) do
        apply(module, fun, args)
      end
    end)
  end

  @doc """
  Apply `fun` to each module (until one fails).
  The `fun` should return :ok, or {:error, error}

  TODO: Change this function name...
  """
  def extension_reduce_while(mod, fun, args) do
    modules = modules(mod)
    arity = Enum.count(args)

    Enum.reduce_while(modules, :ok, fn (module, :ok) ->
      if function_exported?(module, fun, arity) do
        case apply(module, fun, args) do
          :ok -> {:cont, :ok}
          {:error, error} -> {:halt, {:error, error}}
        end
      else
        {:cont, :ok}
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

  def deliver_email(mod, fun, args) do
    apply(email(mod), fun, args)
    |> mailer(mod).deliver()
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

  # User Schema / Context

  # This is duplicated and should be moved somewhere shared. Curator? Curator.Schema?
  def find_user_by_email(mod, email) do
    import Ecto.Query, warn: false

    user(mod)
    |> where([u], u.email == ^email)
    |> repo(mod).one()
  end

  # Config
  def guardian_module(mod) do
    mod.config(:guardian)
  end

  def opaque_guardian(mod) do
    mod.config(:opaque_guardian)
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

  def mailer(mod) do
    mod.config(:mailer)
  end

  def email(mod) do
    mod.config(:email)
  end
end
