
  def find_or_create_from_auth(auth) do
    %Ueberauth.Auth{
      info: %Ueberauth.Auth.Info{email: email, name: _name, image: _avatar_url}
    } = auth

    case Repo.get_by(User, email: email) do
      nil ->
        create_user(%{
          email: email,
        })
      user ->
        {:ok, user}
    end
  end
