if Code.ensure_loaded?(Plug) do
  defmodule Curator.Plug.LoadResource do
    @moduledoc """
    This module is a copy of the Guardian.Plug.LoadRecource module, slightly modified:

    In the AuthenticatedPipeline, if the claims are blank an error is raised (so
    sign-in is required).

    In the UnauthenticatedPipeline, allow_unauthenticated should be set to true.
    This allows a sign-in to be optional.

    In both cases, if claims exists, the user must be found or an error will be
    raised (and the session ended). This differs from the Guardian plug, where
    'allow_blank' would not produce an error when there are claims but no
    resource. For example, if a User is deleted, their session could still be
    active, allowing them to visit the unauthenticated resources. This change
    means they'll be signed out immediatly when the resource no longer exists.
    """

    import Plug.Conn

    alias Guardian.Plug, as: GPlug
    alias Guardian.Plug.Pipeline

    def init(opts), do: opts

    def call(conn, opts) do
      allow_unauthenticated = Keyword.get(opts, :allow_unauthenticated, false)

      conn
      |> GPlug.current_claims(opts)
      |> resource(conn, opts)
      |> respond(allow_unauthenticated)
    end

    defp resource(nil, conn, opts), do: {:error, :no_claims, conn, opts}

    defp resource(claims, conn, opts) do
      module = Pipeline.fetch_module!(conn, opts)

      case apply(module, :resource_from_claims, [claims]) do
        {:ok, resource} -> {:ok, resource, conn, opts}
        {:error, reason} -> {:error, reason, conn, opts}
        _ -> {:error, :no_resource_found, conn, opts}
      end
    end

    defp respond({:error, :no_claims, conn, _opts}, true), do: conn
    defp respond({:error, :no_claims, conn, opts}, false), do: return_error(conn, :no_claims, opts)

    defp respond({:error, reason, conn, opts}, _) do
      guardian_plug_module = Module.concat(Pipeline.fetch_module!(conn, opts), Plug)

      conn
      |> guardian_plug_module.sign_out(opts)
      |> return_error(reason, opts)
    end

    defp respond({:ok, resource, conn, opts}, _),
      do: GPlug.put_current_resource(conn, resource, opts)

    defp return_error(conn, reason, opts) do
      handler = Pipeline.fetch_error_handler!(conn, opts)
      conn = apply(handler, :auth_error, [conn, {:load_resource, reason}, opts])
      halt(conn)
    end
  end
end
