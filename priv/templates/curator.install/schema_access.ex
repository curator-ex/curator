
  def get_user(id) do
    case Repo.get(User, id) do
      nil -> {:error, :no_resource_found}
      record -> {:ok, record}
    end
  end
