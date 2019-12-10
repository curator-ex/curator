defmodule Curator.DatabaseAuthenticatableTest do
  @moduledoc false

  use ExUnit.Case, async: true

  defmodule User do
    use Ecto.Schema
    import Ecto.Changeset

    schema "users" do
      field(:email, :string)

      # DatabaseAuthenticatable
      field(:password, :string, virtual: true)
      field(:password_hash, :string)

      timestamps()
    end

    @doc false
    def changeset(%User{} = user, attrs) do
      user
      |> cast(attrs, [:email, :password])
      |> validate_required([:email])
    end
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
    use Curator.DatabaseAuthenticatable,
      otp_app: :curator,
      curator: Curator.DatabaseAuthenticatableTest.CuratorImpl

    def after_verify_password_failure(%{email: "exception@test.com"}) do
      raise "Password Failure"
    end

    def after_verify_password_failure(_user) do
      nil
    end
  end

  defmodule CuratorImpl do
    use Curator,
      otp_app: :curator,
      guardian: GuardianImpl,
      modules: [
        DatabaseAuthenticatableImpl
      ]

    def find_user_by_email("test@test.com") do
      %{
        email: "test@test.com",
        password_hash: "$2b$12$kmIIozbAUtpTILVM9QuwU.0AAJCtqnYhBLwJ/6UBLfLkdllKAa7XO"
      }
    end

    def find_user_by_email("exception@test.com") do
      %{
        email: "exception@test.com",
        password_hash: "$2b$12$kmIIozbAUtpTILVM9QuwU.0AAJCtqnYhBLwJ/6UBLfLkdllKAa7XO"
      }
    end

    def find_user_by_email(_) do
      nil
    end
  end

  describe "create_changeset" do
    test "password is hashed" do
      attrs = %{
        password: "not_hashed"
      }

      changeset = DatabaseAuthenticatableImpl.create_changeset(%User{}, attrs)

      assert changeset.valid?

      user = Ecto.Changeset.apply_changes(changeset)
      refute user.password
      assert user.password_hash
    end
  end

  describe "update_changeset" do
    test "password is hashed" do
      attrs = %{
        password: "not_hashed"
      }

      changeset = DatabaseAuthenticatableImpl.update_changeset(%User{}, attrs)

      assert changeset.valid?

      user = Ecto.Changeset.apply_changes(changeset)
      refute user.password
      assert user.password_hash
    end
  end

  test "authenticate_user" do
    assert {:ok, _user} =
             DatabaseAuthenticatableImpl.authenticate_user(%{
               email: "test@test.com",
               password: "not_hashed"
             })

    assert {:error, {:database_authenticatable, :invalid_credentials}} =
             DatabaseAuthenticatableImpl.authenticate_user(%{
               email: "test@test.com",
               password: "Xnot_hashed"
             })

    # Test extension :after_verify_password_failure
    assert_raise RuntimeError, fn ->
      DatabaseAuthenticatableImpl.authenticate_user(%{
        email: "exception@test.com",
        password: "Xnot_hashed"
      })
    end
  end
end
