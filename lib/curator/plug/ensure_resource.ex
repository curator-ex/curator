if Code.ensure_loaded?(Plug) do
  defmodule Curator.Plug.EnsureResource do
    @moduledoc """
    This plug ensures that a resource loaded.

    If one is not found, the `auth_error` will be called with `:not_authenticated`

    This should not be used directly, instead the typical curator load_resource plug should be used.
    This is for cases where a controller is generated and we want to be certain it's configured correctly

    This, like all other Guardian plugs, requires a Guardian pipeline to be setup.
    It requires an implementation module, an error handler and a key.

    These can be set either:

    1. Upstream on the connection with `plug Guardian.Pipeline`
    2. Upstream on the connection with `Guardian.Pipeline.{put_module, put_error_handler, put_key}`
    3. Inline with an option of `:module`, `:error_handler`, `:key`

    Options:

    * `key` - The location to find the information in the connection. Defaults to: `default`

    ## Example

    ```elixir

      # setup the upstream pipeline
      plug Curator.Plug.EnsureResource
      plug Curator.Plug.EnsureResource, key: :secret
      ```
    """
    import Plug.Conn

    alias Guardian.Plug, as: GPlug
    alias GPlug.{Pipeline}

    def init(opts), do: opts

    def call(conn, opts) do
      resource = GPlug.current_resource(conn, opts)

      unless resource do
        conn
        |> Pipeline.fetch_error_handler!(opts)
        |> apply(:auth_error, [conn, {:ensure_resource, :not_authenticated}, opts])
        |> halt()
      else
        conn
      end
    end
  end
end
