
  def get_token(id) do
    case Repo.get(Token, id) do
      nil -> {:error, :no_resource_found}
      record -> {:ok, record}
    end
  end
