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
    config(:hooks_module, Guardian) # or CuratorSession
  end

  def api_session_handler do
    config(:hooks_module, Guardian) # or CuratorToken
  end

  def repo do
    config(:repo)
  end

  def user_schema do
    config(:user_schema)
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
