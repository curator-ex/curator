defmodule Curator.Plug.EnsureResourceAndSession do
  @moduledoc """
  This plug ensures that the current_resource has been set, usually in
  Guardian.Plug.LoadResource.

  If one is not found, the `no_resource/2` function is invoked with the
  `Plug.Conn.t` object and its params.

  ## Example

      # Will call the no_resource/2 function on your handler
      plug Curator.Plug.EnsureResourceAndSession, handler: SomeModule

      # look in the :secret location.
      plug Curator.Plug.EnsureResourceAndSession, handler: SomeModule, key: :secret

  If the handler option is not passed, `Guardian.Plug.ErrorHandler` will provide
  the default behavior.
  """
  import Plug.Conn

  @doc false
  def init(opts) do
    opts = Enum.into(opts, %{})
    handler = build_handler_tuple(opts)

    %{
      handler: handler,
      key: Map.get(opts, :key, :default)
    }
  end

  @doc false
  def call(conn, opts) do
    key = Map.get(opts, :key, :default)

    case Guardian.Plug.claims(conn, key) do
      {:ok, _claims} ->
        case Guardian.Plug.current_resource(conn, key) do
          nil -> handle_error(conn, :no_resource, opts)
          _ -> conn
        end
      {:error, reason} -> handle_error(conn, reason, opts)
    end
  end

  defp handle_error(%Plug.Conn{params: params} = conn, reason, opts) do
    conn = conn |> assign(:guardian_failure, reason) |> halt
    params = Map.merge(params, %{reason: reason})
    {mod, meth} = Map.get(opts, :handler)

    apply(mod, meth, [conn, params])
  end

  defp build_handler_tuple(%{handler: mod}) do
    {mod, :no_resource}
  end
  defp build_handler_tuple(_) do
    {Guardian.Plug.ErrorHandler, :no_resource}
  end
end
