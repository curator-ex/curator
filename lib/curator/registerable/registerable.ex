defmodule Curator.Registerable do
  use Curator.Extension

  defmacro __using__(opts \\ []) do
    quote do
      use Curator.Config, unquote(opts)
      use Curator.Extension, mod: Curator.Registerable
    end
  end

  def unauthenticated_routes() do
    quote do
      resources "/registrations", Auth.RegistrationController, only: [:new, :create]
      get "/registrations/edit", Auth.RegistrationController, :edit
      get "/registrations", Auth.RegistrationController, :show
      put "/registrations", Auth.RegistrationController, :update, as: nil
      patch "/registrations", Auth.RegistrationController, :update
      delete "/registrations", Auth.RegistrationController, :delete
    end
  end
end
