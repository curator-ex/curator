defmodule Curator.Router do
  @router_macros [
    :unauthenticated_plugs,
    :authenticated_plugs,
    :unauthenticated_routes,
    :authenticated_routes,
  ]

  def get_module_quotes(curator_module, method_name) when method_name in @router_macros do
    modules = modules(curator_module)

    Enum.map(modules, &(apply(&1, method_name, [])))
    |> Enum.filter(&(&1))
  end

  defp modules(curator_module) do
    apply(curator_module, :config, [:modules, []])
  end

  def web_module(curator_module) do
    apply(curator_module, :config, [:web_module])
  end

  defmacro mount_unauthenticated_plugs(curator) do
    curator = Macro.expand(curator, __CALLER__)
    module_quotes = get_module_quotes(curator, :unauthenticated_plugs)

    quote do
      plug Curator.Plug.LoadSession

      unquote(module_quotes)

      plug Curator.Plug.EnsureResourceOrNoSession
    end
  end

  defmacro mount_authenticated_plugs(curator) do
    curator = Macro.expand(curator, __CALLER__)
    module_quotes = get_module_quotes(curator, :authenticated_plugs)

    quote do
      plug Curator.Plug.LoadSession

      unquote(module_quotes)

      plug Curator.Plug.EnsureResourceAndSession
    end
  end

  defmacro mount_unauthenticated_routes(curator) do
    curator = Macro.expand(curator, __CALLER__)
    web_module = web_module(curator)
    module_quotes = get_module_quotes(curator, :unauthenticated_routes)

    quote do
      scope "/auth", unquote(web_module) do
        # get "/session/new", AuthController, :new
        # post "/session", AuthController, :create
        delete "/session", SessionController, :delete

        unquote(module_quotes)
      end
    end
  end

  defmacro mount_authenticated_routes(curator) do
    curator = Macro.expand(curator, __CALLER__)
    web_module = web_module(curator)
    module_quotes = get_module_quotes(curator, :authenticated_routes)

    quote do
      scope "/auth", unquote(web_module) do
        delete "/session", SessionController, :delete

        unquote(module_quotes)
      end
    end
  end
end
