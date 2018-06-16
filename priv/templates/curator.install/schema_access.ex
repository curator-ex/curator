
  def insert_user_changeset(changeset) do
    changeset
    |> Repo.insert()
  end

  def update_user_changeset(changeset) do
    changeset
    |> Repo.update()
  end

