defmodule Curator.Config do
  @moduledoc """
  Working with configuration for guardian.
  """

  @typedoc """
  Configuration values can be given using the following types:

  * `{MyModule, :func, [:some, :args]}` Calls the function on the module with args
  * any other value
  """
  @type config_value :: {module, atom, list(any)} | any

  @doc """
  Resolves possible values from a configuration.

  * `{m, f, a}` - Calls function `f` on module `m` with arguments `a` and returns the result
  * value - Returns other values as is
  """
  @spec resolve_value(value :: config_value) :: any
  def resolve_value({m, f, a}) when is_atom(m) and is_atom(f), do: apply(m, f, a)
  def resolve_value(v), do: v

  defmacro __using__(opts \\ []) do
    alias Curator.Config, as: Config

    otp_app = Keyword.get(opts, :otp_app)

    quote do
      the_otp_app = unquote(otp_app)
      the_opts = unquote(opts)

      # Provide a way to get at the configuration during compile time
      # for other macros that may want to use them
      @config fn ->
        the_otp_app |> Application.get_env(__MODULE__, []) |> Keyword.merge(the_opts)
      end
      @config_with_key fn key -> @config.() |> Keyword.get(key) |> Config.resolve_value() end
      @config_with_key_and_default fn key, default ->
        @config.() |> Keyword.get(key, default) |> Config.resolve_value()
      end

      @doc """
      Fetches the configuration for this module
      """
      @spec config() :: Keyword.t()
      def config,
        do: unquote(otp_app)
            |> Application.get_env(__MODULE__, [])
            |> Keyword.merge(unquote(opts))

      @doc """
      Returns a resolved value of the configuration found at a key

      See `Curator.Config.resolve_value`
      """
      @spec config(atom | String.t(), any) :: any
      def config(key, default \\ nil),
        do: config() |> Keyword.get(key, default) |> Config.resolve_value()
    end
  end
end
