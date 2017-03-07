defmodule Curator.Plug.EnsureAuthenticated do
  alias Curator.Config

  def init(opts) do
    Module.concat([Config.session_handler, EnsureAuthenticated]).init(opts)
  end

  def call(conn, opts) do
    Module.concat([Config.session_handler, EnsureAuthenticated]).call(conn, opts)
  end
end
