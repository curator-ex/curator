defmodule Curator2 do
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

  defmacro __using__(opts \\ []) do
    quote do
      use Curator.Config2, unquote(opts)
      @behaviour Curator2

      # if Code.ensure_loaded?(Plug) do
      #   __MODULE__
      #   |> Module.concat(:Plug)
      #   |> Module.create(
      #        quote do
      #          use Curator.Plug, unquote(__MODULE__)
      #        end,
      #        Macro.Env.location(__ENV__)
      #      )
      # end

      def before_sign_in(user, opts \\ []),
        do: Curator2.before_sign_in(__MODULE__, user, opts)

      def after_sign_in(conn, user, opts \\ []),
        do: Curator2.after_sign_in(__MODULE__, conn, user, opts)

      defoverridable before_sign_in: 2,
                     after_sign_in: 3
    end
  end

  def before_sign_in(mod, user, opts) do
    modules = modules(mod)

    Enum.reduce_while(modules, :ok, fn (module, :ok) ->
      case apply(module, :before_sign_in, [user, opts]) do
        :ok -> {:cont, :ok}
        {:error, error} -> {:halt, {:error, error}}
      end
    end)
  end

  def after_sign_in(mod, conn, user, opts) do
    modules = modules(mod)

    Enum.reduce(modules, conn, fn (module, conn) ->
      apply(module, :after_sign_in, [conn, user, opts])
    end)

    # Enum.reduce_while(modules, {:ok, conn}, fn (module) ->
    #   case apply(module, :after_sign_in, [user, opts]) do
    #     {:ok, conn} -> {:cont, {:ok, conn}}
    #     {:error, error} -> {:halt, {:error, error}}
    #   end
    # end)
  end

  def modules(mod) do
    apply(mod, :config, [:modules, []])
  end

end
