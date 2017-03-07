defmodule Curator.UserSerializer do
  import Curator.Config

  def for_token(user) when user != "" and user != nil, do: { :ok, "User:#{user.id}" }
  def for_token(_), do: { :error, "Unknown resource type" }

  def from_token("User:" <> id), do: { :ok, Config.repo.get(Config.user_schema, id) }
  def from_token(_), do: { :error, "Unknown resource type" }
end
