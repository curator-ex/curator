defmodule Curator.Config do
  @moduledoc """
  The configuration for Curator.
  It also provides default repo & user_schema configuration for curator_* applications.

  ## Configuration

      config :curator, Curator,
        hooks_module: Curator.Hooks.Default

  """

  def hooks_module do
    config(:hooks_module, Curator.Hooks.Default)
  end

  def session_handler do
    config(:session_handler, Curator.SessionHandlers.SimpleSession)
  end

  # def api_session_handler do
  #   config(:api_session_handler, Curator.ApiSessionHandlers.Guardian)
  # end

  def repo do
    config(:repo)
  end

  def user_schema do
    config(:user_schema)
  end

  def error_handler do
    config(:error_handler)
  end

  def context do
    config(:context)
  end

  def modules do
    config(:modules, [])
  end

  def module_enabled?(module) do
    Enum.member?(modules(), module)
  end

  def web_module do
    config(:web_module)
  end

  @doc false
  def config, do: Application.get_env(:curator, Curator, [])
  @doc false
  def config(key, default \\ nil),
    do: config() |> Keyword.get(key, default) |> resolve_config(default)

  defp resolve_config({:system, var_name}, default),
    do: System.get_env(var_name) || default
  defp resolve_config(value, _default),
    do: value
end
