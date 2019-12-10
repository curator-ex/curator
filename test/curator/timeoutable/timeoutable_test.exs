defmodule Curator.TimeoutableTest do
  @moduledoc false

  use ExUnit.Case, async: true

  defmodule User do
    use Ecto.Schema
    import Ecto.Changeset

    schema "users" do
      field(:email, :string)

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

  defmodule TimeoutableImpl do
    use Curator.Timeoutable, otp_app: :curator
  end

  defmodule CuratorImpl do
    use Curator,
      otp_app: :curator,
      guardian: GuardianImpl,
      modules: [
        TimeoutableImpl
      ]
  end

  test "after_sign_in" do
    conn =
      Phoenix.ConnTest.build_conn()
      |> Plug.Test.init_test_session(%{})

    user = %User{
      email: "test@test.com"
    }

    refute Plug.Conn.get_session(conn, "guardian_default_timeoutable")
    conn = CuratorImpl.after_sign_in(conn, user)
    assert Plug.Conn.get_session(conn, "guardian_default_timeoutable")
  end
end
