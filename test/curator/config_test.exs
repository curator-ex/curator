defmodule Curator.ConfigTest do
  use ExUnit.Case, async: true
  doctest Curator.Config

  test "the default hooks_module" do
    assert Curator.Config.hooks_module == Curator.Hooks.Default
  end
end
