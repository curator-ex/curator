defmodule Curator.Plug.EnsureResourceAndSession do
  alias Curator.Config

  def init(opts) do
    Module.concat([Config.session_handler, EnsureResourceAndSession]).init(opts)
  end

  def call(conn, opts) do
    Module.concat([Config.session_handler, EnsureResourceAndSession]).call(conn, opts)
  end
end
