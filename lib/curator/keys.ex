defmodule Curator.Keys do
  @moduledoc false

  def claims_key(key \\ :default) do
    String.to_atom("#{base_key(key)}_claims")
  end

  def token_key(key \\ :default) do
    String.to_atom("#{base_key(key)}_token")
  end

  def resource_key(key \\ :default) do
    String.to_atom("#{base_key(key)}_resource")
  end

  def base_key(the_key = "curator_" <> _) do
    String.to_atom(the_key)
  end

  def base_key(the_key) do
    String.to_atom("curator_#{the_key}")
  end
end
