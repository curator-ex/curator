defmodule Curator.Plug.EnsureResourceOrNoSession do
  alias Curator.Config

  def init(opts) do
    Module.concat([Config.session_handler, EnsureResourceOrNoSession]).init(opts)
  end

  def call(conn, opts) do
    Module.concat([Config.session_handler, EnsureResourceOrNoSession]).call(conn, opts)
  end
end
