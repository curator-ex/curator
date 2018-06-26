defmodule Curator.Ueberauth do
  @moduledoc """
  TODO

  Options:

  N/A

  Extensions:

  N/A

  """

  use Curator.Extension

  defmacro __using__(opts \\ []) do
    quote do
      use Curator.Config, unquote(opts)
      use Curator.Extension, mod: Curator.Ueberauth
    end
  end

  # Extensions

  def unauthenticated_routes() do
    quote do
      scope "/auth" do
        get "/:provider", Auth.UeberauthController, :request
        get "/:provider/callback", Auth.UeberauthController, :callback
        post "/:provider/callback", Auth.UeberauthController, :callback
      end
    end
  end
end
