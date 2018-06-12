
  def get_token_by_id(token_id) do
    case Repo.get_by(Token, %{token: token_id}) do
      nil ->
        {:error, :not_found}
      token ->
        {:ok, token}
    end
  end
