defmodule Curator.ConfirmableTest do
  @moduledoc false

  use ExUnit.Case, async: true

  defmodule User do
    use Ecto.Schema
    import Ecto.Changeset

    schema "users" do
      field :email, :string

      # Confirmable
      field :email_confirmed_at, :utc_datetime

      timestamps()
    end

    @doc false
    def changeset(%User{} = user, attrs) do
      user
      |> cast(attrs, [:email])
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

  defmodule ConfirmableImpl do
    use Curator.Confirmable, otp_app: :curator,
      curator: Curator.ConfirmableTest.CuratorImpl
  end

  defmodule CuratorImpl do
    use Curator, otp_app: :curator,
      guardian: GuardianImpl,
      modules: [
        ConfirmableImpl,
      ]
  end

  describe "verify_confirmed" do
    test "returns true when email_confirmed_at is set" do
      user = %User{email_confirmed_at: Timex.now()}
      assert :ok == ConfirmableImpl.verify_confirmed(user)
    end

    test "returns an error when email_confirmed_at is NOT set" do
      user = %User{email_confirmed_at: nil}
      assert {:error, {:confirmable, :email_not_confirmed}} == ConfirmableImpl.verify_confirmed(user)
    end
  end

  # describe "after_create_registration" do
  # end

  # describe "after_update_registration" do
  # end

  # describe "process_token" do
  # end

  describe "update_registerable_changeset" do
    test "when email is changed, email_confirmed_at is cleared" do
      attrs = %{
        email: "me@my.home",
      }

      user = %User{
        email: "you@your.home",
        email_confirmed_at: Timex.now()
      }

      changeset = Ecto.Changeset.cast(user, attrs, [:email])
      |> ConfirmableImpl.update_registerable_changeset(attrs)

      assert changeset.valid?

      user = Ecto.Changeset.apply_changes(changeset)
      refute user.email_confirmed_at
    end

    test "when email is NOT changed, email_confirmed_at is NOT cleared" do
      attrs = %{
        email: "me@my.home",
      }

      user = %User{
        email: "me@my.home",
        email_confirmed_at: Timex.now()
      }

      changeset = Ecto.Changeset.cast(user, attrs, [:email])
      |> ConfirmableImpl.update_registerable_changeset(attrs)

      assert changeset.valid?

      user = Ecto.Changeset.apply_changes(changeset)
      assert user.email_confirmed_at
    end
  end
end
