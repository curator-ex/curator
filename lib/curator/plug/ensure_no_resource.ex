if Code.ensure_loaded?(Plug) do
  defmodule Curator.Plug.EnsureNoResource do
    @moduledoc """
    This plug ensures that a resource is not loaded.

    If one is found, the `auth_error` will be called with `:already_authenticated`

    This might be used directly, however the typical curator load_resource plug should be used.
    If there is a case where it's imperative the user isn't signed in this will accomplish that.

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
      plug Curator.Plug.EnsureNoResource
      plug Curator.Plug.EnsureNoResource, key: :secret
      ```
    """
    import Plug.Conn

    alias Guardian.Plug, as: GPlug
    alias GPlug.{Pipeline}

    def init(opts), do: opts

    def call(conn, opts) do
      resource = GPlug.current_resource(conn, opts)

      if resource do
        conn
        |> Pipeline.fetch_error_handler!(opts)
        |> apply(:auth_error, [conn, {:ensure_no_resource, :already_authenticated}, opts])
        |> halt()
      else
        conn
      end
    end
  end
end
