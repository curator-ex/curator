defmodule Curator.Lockable.Plug do
  import Plug.Conn

  alias Guardian.Plug.Pipeline

  @moduledoc """
  """

  def init(opts), do: opts

  def call(conn, opts) do
    guardian_plug_module = Module.concat(Pipeline.fetch_module!(conn, opts), Plug)

    conn
    |> guardian_plug_module.current_resource(opts)
    |> verify?(conn, opts)
    |> respond()
  end

  defp verify?(resource, conn, opts) do
    lockable_module = Keyword.fetch!(opts, :lockable_module)

    case lockable_module.verify_unlocked(resource) do
      :ok ->
        {:ok, resource, conn, opts}
      {:error, error} ->
        {:error, error, conn, opts}
    end
  end

  defp respond({:ok, nil, conn, _opts}), do: conn

  defp respond({:ok, _resource, conn, _opts}), do: conn

  defp respond({:error, reason, conn, opts}) do
    return_error(conn, reason, opts)
  end

  defp return_error(conn, reason, opts) do
    handler = Pipeline.fetch_error_handler!(conn, opts)
    conn = apply(handler, :auth_error, [conn, reason, opts])
    halt(conn)
  end
end
