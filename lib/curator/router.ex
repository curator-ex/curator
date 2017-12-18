defmodule Curator.Router do
  require Curator.Ueberauth

  defmacro __using__(_) do
  end

  defmacro mount_unauthenticated_plugs do
    module_quotes = get_module_quotes(modules, :unauthenticated_plugs)

    quote do
      plug Curator.Plug.LoadSession

      unquote(module_quotes)

      plug Curator.Plug.EnsureResourceOrNoSession
    end
  end

  defmacro mount_authenticated_plugs do
    module_quotes = get_module_quotes(modules, :authenticated_plugs)

    quote do
      plug Curator.Plug.LoadSession

      unquote(module_quotes)

      plug Curator.Plug.EnsureResourceAndSession
    end
  end

  defmacro mount_unauthenticated_routes(modules \\ nil) do
    web_module = Curator.Config.web_module()
    module_quotes = get_module_quotes(modules, :unauthenticated_routes)

    quote do
      scope "/auth", unquote(web_module) do
        # get "/session/new", AuthController, :new
        # post "/session", AuthController, :create
        delete "/session", SessionController, :delete

        unquote(module_quotes)
      end
    end
  end

  defmacro mount_authenticated_routes(modules \\ nil) do
    web_module = Curator.Config.web_module()
    module_quotes = get_module_quotes(modules, :authenticated_routes)

    quote do
      scope "/auth", unquote(web_module) do
        unquote(module_quotes)
      end
    end
  end

  defp get_module_quotes(modules, method_name) do
    modules = case modules do
      nil -> Curator.Config.modules()
      _ -> modules
    end

    all_module_routes = Enum.reduce(modules, [], fn (module, acc) ->
      acc ++ [apply(module, method_name, [])]
    end)
    |> Enum.filter(&(&1))
  end
end
