defmodule Curator.LockableTest do
  @moduledoc false

  use ExUnit.Case, async: true

  defmodule User do
    use Ecto.Schema
    import Ecto.Changeset

    schema "users" do
      field :email, :string

      # Lockable
      field :failed_attempts, :integer
      field :locked_at, Timex.Ecto.DateTime

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

  defmodule LockableImpl do
    use Curator.Lockable, otp_app: :curator,
      curator: Curator.LockableTest.CuratorImpl
  end

  defmodule LockableImplTime do
    use Curator.Lockable, otp_app: :curator,
      curator: Curator.LockableTest.CuratorImpl,
      unlock_strategy: [:time],
      unlock_in: [hours: 12]

  end

  defmodule CuratorImpl do
    use Curator, otp_app: :curator,
      guardian: GuardianImpl,

      modules: [
        LockableImpl,
      ]
  end

  describe "verify_unlocked" do
    test "returns :ok when locked_at is nil" do
      user = %User{locked_at: nil}
      assert :ok == LockableImpl.verify_unlocked(user)
    end

    test "returns an error when locked_at is NOT nil" do
      user = %User{locked_at: Timex.now()}
      assert {:error, {:lockable, :account_locked}} == LockableImpl.verify_unlocked(user)
    end

    test "return an error when locked_at is NOT nil AND lock_expired (but time is not an unlock strategy)" do
      user = %User{locked_at: Timex.now |> Timex.shift(days: -1)}
      assert {:error, {:lockable, :account_locked}} == LockableImpl.verify_unlocked(user)
    end

    test "return an error when locked_at is NOT nil AND NOT lock_expired (and time is NOT an unlock strategy)" do
      user = %User{locked_at: Timex.now |> Timex.shift(hours: -11)}
      assert {:error, {:lockable, :account_locked}} == LockableImplTime.verify_unlocked(user)
    end

    test "return :ok when locked_at is NOT nil AND lock_expired (and time is an unlock strategy)" do
      user = %User{locked_at: Timex.now |> Timex.shift(hours: -13)}
      assert :ok == LockableImplTime.verify_unlocked(user)
    end
  end

  # describe "after_create_registration" do
  # end

  # describe "after_update_registration" do
  # end

  # describe "process_token" do
  # end
end
