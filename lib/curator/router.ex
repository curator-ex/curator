defmodule Curator.Router do
  @router_macros [
    :unauthenticated_routes,
    :authenticated_routes
  ]

  def get_module_quotes(curator_module, method_name) when method_name in @router_macros do
    modules = modules(curator_module)

    Enum.map(modules, &apply(&1, method_name, []))
    |> Enum.filter(& &1)
  end

  defp modules(curator_module) do
    apply(curator_module, :config, [:modules, []])
  end

  defmacro mount_unauthenticated_routes(curator) do
    curator = Macro.expand(curator, __CALLER__)
    module_quotes = get_module_quotes(curator, :unauthenticated_routes)

    quote do
      get("/session/new", Auth.SessionController, :new)
      get("/session", Auth.SessionController, :new)
      # post "/session", Auth.SessionController, :create
      # delete "/session", Auth.SessionController, :delete

      unquote(module_quotes)
    end
  end

  defmacro mount_authenticated_routes(curator) do
    curator = Macro.expand(curator, __CALLER__)
    module_quotes = get_module_quotes(curator, :authenticated_routes)

    quote do
      # get "/session/new", Auth.SessionController, :new
      # post "/session", Auth.SessionController, :create
      delete("/session", Auth.SessionController, :delete)

      unquote(module_quotes)
    end
  end
end
