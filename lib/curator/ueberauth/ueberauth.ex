defmodule Curator.Ueberauth do
  use Curator.Extension#, plug: Curator.Ueberauth.Plug
  # controller_name: ...

  def unauthenticated_routes() do
    quote do
      get "/:provider", UeberauthController, :request
      get "/:provider/callback", UeberauthController, :callback
      post "/:provider/callback", UeberauthController, :callback
    end
  end
end

# defmodule Houston.Curator.Ueberauth
#   use Curator.Ueberauth, config...

#   def unauthenticated_routes() do
#     quote do
#       get "/:provider", MyController, :request
#       get "/:provider/callback", MyController, :callback
#       post "/:provider/callback", MyController, :callback
#     end
#   end
# end
