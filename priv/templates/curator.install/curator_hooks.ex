defmodule <%= inspect context.web_module %>.Auth.CuratorHooks do
  use <%= inspect context.web_module %>, :controller
  use Curator.Hooks

  # import Curator.Hooks.Default
end
