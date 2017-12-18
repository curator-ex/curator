defmodule Curator.Ueberauth do
  use Curator.Extension

  def unauthenticated_routes do
    quote do
      get "/:provider", UeberauthController, :request
      get "/:provider/callback", UeberauthController, :callback
      post "/:provider/callback", UeberauthController, :callback
    end
  end
end
