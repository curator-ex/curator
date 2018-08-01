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

      # TODO: Remove from generator and integrate with controller
      # def find_or_create_from_auth(auth),
      #   do: Curator.Ueberauth.find_or_create_from_auth(__MODULE__, auth)

      use Curator.Config, unquote(opts)
      use Curator.Extension, mod: Curator.Ueberauth
    end
  end

  # TODO: This should be able to integrate with a registration workflow
  # def find_or_create_from_auth(mod, auth) do
  #   %Ueberauth.Auth{
  #     info: %Ueberauth.Auth.Info{email: email, name: _name, image: _avatar_url}
  #   } = auth

  #   case Repo.get_by(User, email: email) do
  #     nil ->
  #       create_user(%{
  #         email: email,
  #       })
  #     user ->
  #       {:ok, user}
  #   end
  # end

  # Extensions

  def unauthenticated_routes(_mod) do
    quote do
      scope "/auth" do
        get "/:provider", Auth.UeberauthController, :request
        get "/:provider/callback", Auth.UeberauthController, :callback
        post "/:provider/callback", Auth.UeberauthController, :callback
      end
    end
  end
end
