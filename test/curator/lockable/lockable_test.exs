defmodule Curator.LockableTest do
  @moduledoc false

  use ExUnit.Case, async: true

  defmodule User do
    use Ecto.Schema
    import Ecto.Changeset

    schema "users" do
      field(:email, :string)

      # Lockable
      field(:failed_attempts, :integer)
      field(:locked_at, :utc_datetime)

      timestamps()
    end

    @doc false
    def changeset(%User{} = user, attrs) do
      user
      |> cast(attrs, [:email])
      |> validate_required([:email])
    end
  end

  defmodule Repo do
    import Ecto.Changeset

    def update!(user) do
      apply_changes(user)
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

  # defmodule GuardianOpaqueImpl do
  #   use Guardian,
  #     otp_app: :curator,
  #     token_module: Curator.Guardian.Token.Opaque
  #
  #   use Curator.Guardian.Token.Opaque.ContextAdapter, context: Auth
  #
  #   def subject_for_token(user, _claims) do
  #     sub = to_string(user.id)
  #     {:ok, sub}
  #   end
  #
  #   def resource_from_claims(claims) do
  #     claims["sub"]
  #     |> get_user()
  #   end
  #
  #   def get_user(1) do
  #     {:ok, %{id: 1}}
  #   end
  #
  #   def get_user(_) do
  #     {:error, :not_found}
  #   end
  # end

  defmodule LockableImpl do
    use Curator.Lockable,
      otp_app: :curator,
      curator: Curator.LockableTest.CuratorImpl
  end

  defmodule LockableImplTime do
    use Curator.Lockable,
      otp_app: :curator,
      curator: Curator.LockableTest.CuratorImpl,
      unlock_strategy: [:time],
      unlock_in: [hours: 12]
  end

  defmodule LockableImplEmail do
    use Curator.Lockable,
      otp_app: :curator,
      curator: Curator.LockableTest.CuratorImpl,
      unlock_strategy: [:email]
  end

  defmodule CuratorImpl do
    use Curator,
      otp_app: :curator,
      guardian: GuardianImpl,
      # opaque_guardian: GuardianOpaqueImpl,
      repo: Repo,
      modules: [
        LockableImpl
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

    test "returns an error when locked_at is NOT nil AND lock is expired (but time is not an unlock strategy)" do
      user = %User{locked_at: Timex.now() |> Timex.shift(days: -1)}
      assert {:error, {:lockable, :account_locked}} == LockableImpl.verify_unlocked(user)
    end

    test "return an error when locked_at is NOT nil AND lock is not expired (and time is NOT an unlock strategy)" do
      user = %User{locked_at: Timex.now() |> Timex.shift(hours: -11)}
      assert {:error, {:lockable, :account_locked}} == LockableImplTime.verify_unlocked(user)
    end

    test "return :ok when locked_at is NOT nil AND lock_expired (and time is an unlock strategy)" do
      user = %User{locked_at: Timex.now() |> Timex.shift(hours: -13)}
      assert :ok == LockableImplTime.verify_unlocked(user)
    end
  end

  # describe "process_token" do
  # end

  describe "after_verify_password_success" do
    test "it clears locked_at and resets failed_attempts to 0" do
      user = %User{locked_at: Timex.now(), failed_attempts: 5}
      user = LockableImpl.after_verify_password_success(user)
      refute user.locked_at
      assert user.failed_attempts == 0
    end
  end

  describe "after_verify_password_failure" do
    test "it increments the failed_attempts counter" do
      user = %User{locked_at: nil, failed_attempts: 0}
      user = LockableImpl.after_verify_password_failure(user)
      refute user.locked_at
      assert user.failed_attempts == 1
    end

    test "it locks the user when failed_attempts equals the maximum_attempts config" do
      user = %User{locked_at: nil, failed_attempts: 4}
      user = LockableImpl.after_verify_password_failure(user)
      assert user.locked_at
      assert user.failed_attempts == 5
    end

    test "it doesn't update the locked_at timestamp on subsequent failures" do
      original_user = %User{locked_at: Timex.now() |> Timex.shift(hours: -13), failed_attempts: 5}
      user = LockableImpl.after_verify_password_failure(original_user)
      assert user.locked_at
      assert original_user.locked_at == user.locked_at
      assert user.failed_attempts == 6
    end

    test "it doesn't send an email when the strategy is not configured" do
      user = %User{locked_at: nil, failed_attempts: 4}
      user = LockableImpl.after_verify_password_failure(user)
      assert user.locked_at
    end

    # TODO: create better test fixtures and test the email is sent
    # test "it sends and email when the strategy is configured" do
    #   user = %User{locked_at: nil, failed_attempts: 4}
    #   user = LockableImplEmail.after_verify_password_failure(user)
    #   assert user.locked_at
    # end
  end

  describe "after_password_recovery" do
    test "it clears locked_at and resets failed_attempts to 0" do
      user = %User{locked_at: Timex.now(), failed_attempts: 5}
      user = LockableImpl.after_password_recovery(user)
      refute user.locked_at
      assert user.failed_attempts == 0
    end
  end

  describe "unlock_user" do
    test "it clears locked_at and resets failed_attempts to 0" do
      user = %User{locked_at: Timex.now(), failed_attempts: 5}
      user = LockableImpl.unlock_user(user)
      refute user.locked_at
      assert user.failed_attempts == 0
    end
  end
end
