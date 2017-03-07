defmodule Curator.Plug.LoadSession do
  alias Curator.Config

  def init(opts) do
    Module.concat([Config.session_handler, LoadSession]).init(opts)
  end

  def call(conn, opts) do
    Module.concat([Config.session_handler, LoadSession]).call(conn, opts)
  end
end
