
  def find_user_by_email(email) do
    query = from u in User, where: u.email == ^email
    Repo.one(query)
  end
