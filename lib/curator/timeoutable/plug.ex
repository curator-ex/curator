defmodule Curator.Timeoutable.Plug do
  import Plug.Conn

  alias Guardian.Plug.Pipeline

  @moduledoc """
  Use this hook to set a last_request_at timestamp, and signout if it's greater
  than a configured time
  """

  def init(opts), do: opts

  def call(conn, opts) do
    guardian_plug_module = Module.concat(Pipeline.fetch_module!(conn, opts), Plug)

    conn
    |> guardian_plug_module.current_resource(opts)
    |> verify?(conn, opts)
    |> respond()
  end

  defp verify?(nil, conn, opts), do: {:ok, nil, conn, opts}

  defp verify?(resource, conn, opts) do
    timeoutable_module = Keyword.fetch!(opts, :timeoutable_module)

    case timeoutable_module.verify_timeoutable_timestamp(conn, opts) do
      :ok ->
        {:ok, resource, conn, opts}
      {:error, error} ->
        {:error, error, conn, opts}
    end
  end

  defp respond({:ok, nil, conn, _opts}), do: conn

  defp respond({:ok, _resource, conn, opts}) do
    timeoutable_module = Keyword.fetch!(opts, :timeoutable_module)
    timeoutable_module.update_timeoutable_timestamp(conn, opts)
  end

  defp respond({:error, reason, conn, opts}) do
    return_error(conn, reason, opts)
  end

  defp return_error(conn, reason, opts) do
    handler = Pipeline.fetch_error_handler!(conn, opts)
    conn = apply(handler, :auth_error, [conn, reason, opts])
    halt(conn)
  end
end
