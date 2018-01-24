defmodule Curator.Ueberauth do
  use Curator.Extension

  defmacro __using__(opts \\ []) do
    quote do
      use Curator.Config, unquote(opts)
      use Curator.Extension, mod: Curator.Ueberauth

      # @behaviour Curator.Ueberauth
    end
  end

  def unauthenticated_routes() do
    quote do
      get "/:provider", Auth.UeberauthController, :request
      get "/:provider/callback", Auth.UeberauthController, :callback
      post "/:provider/callback", Auth.UeberauthController, :callback
    end
  end
end
