defmodule Curator.Ueberauth do
  use Curator.Extension

  defmacro __using__(opts \\ []) do
    quote do
      use Curator.Config2, unquote(opts)
      use Curator.Extension, mod: Curator.Ueberauth

      # @behaviour Curator.Ueberauth
    end
  end

  def unauthenticated_routes() do
    quote do
      get "/:provider", UeberauthController, :request
      get "/:provider/callback", UeberauthController, :callback
      post "/:provider/callback", UeberauthController, :callback
    end
  end
end
