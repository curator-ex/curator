defmodule Curator.SessionHandler do
  @moduledoc """
  This module hooks into the curator session.
  """

  @callback current_resource(Plug.Conn.t, atom) :: any | nil

  @callback set_current_resource(Plug.Conn.t, any, atom) :: Plug.Conn.t

  @callback clear_current_resource_with_error(Plug.Conn.t, any, atom) :: Plug.Conn.t

  @callback sign_in(Plug.Conn.t, any) :: Plug.Conn.t

  @callback sign_out(Plug.Conn.t) :: Plug.Conn.t
end
