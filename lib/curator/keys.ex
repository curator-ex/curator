defmodule Curator.Keys do
  @moduledoc false

  def claims_key(key \\ :default) do
    String.to_atom("#{base_key(key)}_claims")
  end

  # def session_key(key \\ :default) do
  #   String.to_atom("#{base_key(key)}_session")
  # end

  @doc false
  def resource_key(key \\ :default) do
    String.to_atom("#{base_key(key)}_resource")
  end

  @doc false
  def base_key(the_key = "curator_" <> _) do
    String.to_atom(the_key)
  end

  @doc false
  def base_key(the_key) do
    String.to_atom("curator_#{the_key}")
  end
end
