defmodule Curator do
  @moduledoc """
  Curator: A framework around User authentication and management.
  """

  # if !Application.get_env(:curator, Curator), do: raise "Curator is not configured"

  @default_token_type "access"
  @default_key :default

  def default_key, do: @default_key

  alias Curator.Config

  @doc """
  call the hooks_module before_sign_in method
  """
  # @spec before_sign_in(term) :: :ok | {:error, atom | String.t}
  # def before_sign_in(resource) do
  #   Config.hooks_module.before_sign_in(resource)
  # end

  @doc """
  call the hooks_module after_sign_in method
  """
  # @spec after_sign_in(Plug.Conn.t, term, atom) :: Plug.Conn.t
  # def after_sign_in(conn, user, the_key \\ @default_key) do
  #   Config.hooks_module.after_sign_in(conn, user, the_key)
  # end

  @doc """
  call the hooks_module after_failed_sign_in method
  """
  @spec after_failed_sign_in(Plug.Conn.t, term, atom) :: Plug.Conn.t
  def after_failed_sign_in(conn, user, the_key \\ @default_key) do
    Config.hooks_module.after_failed_sign_in(conn, user, the_key)
  end

  @doc """
  call the hooks_module after_extension method
  """
  @spec after_extension(Plug.Conn.t, atom, term) :: Plug.Conn.t
  def after_extension(conn, extension, user) do
    Config.hooks_module.after_extension(conn, extension, user)
  end
end
