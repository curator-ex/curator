defmodule Curator.Plug.EnsureNotAuthenticated do
  alias Curator.Config

  def init(opts) do
    Module.concat([Config.session_handler, EnsureNotAuthenticated]).init(opts)
  end

  def call(conn, opts) do
    Module.concat([Config.session_handler, EnsureNotAuthenticated]).call(conn, opts)
  end
end
