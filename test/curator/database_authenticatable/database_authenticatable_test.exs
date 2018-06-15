defmodule Curator.DatabaseAuthenticatableTest do
  @moduledoc false

  use ExUnit.Case, async: true

  defmodule User do
    use Ecto.Schema
    import Ecto.Changeset
    # use Curator.UserSchema,
    #   curator: Curator.DatabaseAuthenticatableTest.CuratorImpl

    schema "users" do
      field :email, :string
      field :password, :string, virtual: true
      field :password_hash, :string
      # curator_schema(Curator.DatabaseAuthenticatableTest.CuratorImpl)

      timestamps()
    end

    @doc false
    def changeset(%User{} = user, attrs) do
      user
      |> cast(attrs, [:email, :password])
      |> validate_required([:email])
      |> put_password_hash()
      # |> curator_validation()
    end

    # Rethinking this... Maybe we can move the different changesets to the Auth context?
    # Then we'd only need to add fields
    defp put_password_hash(%Ecto.Changeset{valid?: true, changes: %{password: password}} = changeset) do
      change(changeset, Comeonin.Bcrypt.add_hash(password))
    end

    defp put_password_hash(changeset), do: changeset
  end

  defmodule GuardianImpl do
    use Guardian,
      otp_app: :curator

    def subject_for_token(user, _claims) do
      sub = to_string(user.id)
      {:ok, sub}
    end

    def resource_from_claims(claims) do
      claims["sub"]
      |> get_user()
    end

    def get_user(1) do
      {:ok, %{id: 1}}
    end

    def get_user(_) do
      {:error, :not_found}
    end
  end

  defmodule DatabaseAuthenticatableImpl do
    use Curator.DatabaseAuthenticatable, otp_app: :curator,
      curator: Curator.DatabaseAuthenticatableTest.CuratorImpl

    def find_user_by_email("test@test.com") do
      %{
        email: "test@test.com",
        password_hash: "$2b$12$kmIIozbAUtpTILVM9QuwU.0AAJCtqnYhBLwJ/6UBLfLkdllKAa7XO",
      }
    end

    def find_user_by_email("exception@test.com") do
      %{
        email: "exception@test.com",
        password_hash: "$2b$12$kmIIozbAUtpTILVM9QuwU.0AAJCtqnYhBLwJ/6UBLfLkdllKAa7XO",
      }
    end

    def find_user_by_email(_) do
      nil
    end

    def verify_password_failure(%{email: "exception@test.com"}) do
      raise "Password Failure"
    end

    def verify_password_failure(_user) do
      nil
    end
  end

  defmodule CuratorImpl do
    use Curator, otp_app: :curator,
      guardian: GuardianImpl,
      modules: [
        DatabaseAuthenticatableImpl,
      ]
  end

  test "changeset" do
    attrs = %{
      email: "test@test.com",
      password: "not_hashed",
    }

    changeset = User.changeset(%User{}, attrs)
    assert changeset.valid?

    user = Ecto.Changeset.apply_changes(changeset)
    assert user.email == "test@test.com"
    refute user.password
    assert user.password_hash
  end

  test "authenticate_user" do
    assert {:ok, _user} = DatabaseAuthenticatableImpl.authenticate_user(%{email: "test@test.com", password: "not_hashed"})
    assert {:error, :invalid_credentials} = DatabaseAuthenticatableImpl.authenticate_user(%{email: "test@test.com", password: "Xnot_hashed"})

    # Test extension :verify_password_failure
    assert_raise RuntimeError, fn ->
      DatabaseAuthenticatableImpl.authenticate_user(%{email: "exception@test.com", password: "Xnot_hashed"})
    end
  end
end
