defmodule Curator.Guardian.Token.OpaqueTest do
  @moduledoc false

  use ExUnit.Case, async: true

  @token_module Curator.Guardian.Token.Opaque

  defmodule Token do
    use Ecto.Schema
    import Ecto.Changeset

    schema "auth_tokens" do
      field(:claims, :map)
      field(:description, :string)
      field(:token, :string)
      field(:user_id, :integer)
      field(:typ, :string)
      field(:exp, :integer)

      timestamps()
    end

    @doc false
    def changeset(token, attrs) do
      token
      |> cast(attrs, [:token, :description, :claims, :user_id, :typ, :exp])
      |> validate_required([:token, :claims, :user_id, :typ])
    end
  end

  # Not quite ecto...
  defmodule Repo do
    alias Curator.Guardian.Token.OpaqueTest.Token

    @token %Token{
      id: 1000,
      token: "v5AaBD39Wr+nZvqqjIyODZn2OcXIIOkLCZs35kS6p+OUR96McpwR1nBK3vn/SF6e",
      user_id: 1,
      claims: %{
        "typ" => "access",
        "sub" => "1",
        "something_else" => "foo"
      },
      typ: "access"
    }

    def insert(changeset) do
      token =
        changeset
        |> Ecto.Changeset.apply_changes()

      if Map.get(token.claims, :error) do
        {:error, :invalid}
      else
        token =
          token
          |> Map.put(:id, 1000)

        {:ok, token}
      end
    end

    def get(Token, 1000) do
      @token
    end

    def get(Token, "1000") do
      @token
    end

    def get(_, _) do
      nil
    end
  end

  defmodule Auth do
    alias Curator.Guardian.Token.OpaqueTest.Token
    alias Curator.Guardian.Token.OpaqueTest.Repo

    def get_token(id) do
      case Repo.get(Token, id) do
        nil -> {:error, :no_resource_found}
        record -> {:ok, record}
      end
    end

    def create_token(attrs \\ %{}) do
      struct(Token, %{})
      |> Token.changeset(attrs)
      |> Repo.insert()
    end

    def delete_token(%Token{} = token) do
      Repo.delete(token)
    end
  end

  defmodule GuardianImpl do
    use Guardian,
      otp_app: :curator,
      token_module: Curator.Guardian.Token.Opaque,
      token_ttl: %{
        "api" => {0, :never},
        "confirmation" => {7, :day}
      }

    alias Curator.Guardian.Token.OpaqueTest.Auth

    def subject_for_token(user, _claims) do
      sub = to_string(user.id)
      {:ok, sub}
    end

    def resource_from_claims(claims) do
      claims["sub"]
      |> get_user()
    end

    use Curator.Guardian.Token.Opaque.ContextAdapter, context: Auth

    def get_user(1) do
      {:ok, %{id: 1}}
    end

    def get_user(_) do
      {:error, :not_found}
    end
  end

  @token_id "v5AaBD39Wr+nZvqqjIyODZn2OcXIIOkLCZs35kS6p+OUR96McpwR1nBK3vn/SF6e1000"
  @invalid_token_id "XXXaBD39Wr+nZvqqjIyODZn2OcXIIOkLCZs35kS6p+OUR96McpwR1nBK3vn/SF6e1000"

  @claims %{
    "typ" => "access",
    "sub" => "1",
    "something_else" => "foo"
  }

  describe "peek" do
    test "with a nil token" do
      result = @token_module.peek(GuardianImpl, nil)

      assert result == nil
    end

    test "with a valid token" do
      result = @token_module.peek(GuardianImpl, @token_id)

      assert result == %{
               claims: %{
                 "something_else" => "foo",
                 "sub" => "1",
                 "typ" => "access"
               }
             }
    end

    test "with an invalid token" do
      result = @token_module.peek(GuardianImpl, @invalid_token_id)

      assert result == nil
    end
  end

  describe "create_token" do
    test "(when valid) creates a token " do
      {:ok, _token_id} = @token_module.create_token(GuardianImpl, @claims)
    end

    test "(when invalid) returns an error" do
      {:error, :invalid} = @token_module.create_token(GuardianImpl, %{error: "invalid"})
    end
  end

  describe "decode_token" do
    test "with a valid token, returns the claims" do
      {:ok, @claims} = @token_module.decode_token(GuardianImpl, @token_id)
    end

    test "with an invalid token, returns an error" do
      {:error, :invalid} = @token_module.decode_token(GuardianImpl, @invalid_token_id)
    end

    test "with a mal-formed token, returns an error" do
      {:error, :invalid} = @token_module.decode_token(GuardianImpl, "NOT_A_REAL_TOKEN")
    end

    test "with a nil token, returns an error" do
      {:error, :invalid} = @token_module.decode_token(GuardianImpl, nil)
    end
  end

  describe "build_claims" do
    @user %{id: "1"}

    test "it adds some fields" do
      {:ok, result} = @token_module.build_claims(GuardianImpl, @user, "1")

      assert result["typ"] == "access"
      assert result["sub"] == "1"
    end

    test "it keeps other fields that have been added" do
      assert {:ok, result} = @token_module.build_claims(GuardianImpl, @user, "1", %{my: "claim"})
      assert result["my"] == "claim"
    end

    test "sets the token 'typ'" do
      assert {:ok, result} = @token_module.build_claims(GuardianImpl, @user, "1", %{})
      assert result["typ"] == "access"

      assert {:ok, result} =
               @token_module.build_claims(GuardianImpl, @user, "1", %{}, token_type: "refresh")

      assert result["typ"] == "refresh"
    end

    test "sets the token 'exp'" do
      assert {:ok, result} = @token_module.build_claims(GuardianImpl, @user, "1", %{})
      assert result["exp"] == nil

      assert {:ok, result} =
               @token_module.build_claims(GuardianImpl, @user, "1", %{},
                 token_type: "confirmation"
               )

      diff = Guardian.timestamp() + 7 * 24 * 60 * 60 - result["exp"]
      assert diff <= 1

      assert {:ok, result} = @token_module.build_claims(GuardianImpl, @user, "1", %{exp: 1000})
      assert result["exp"] == 1000

      assert {:ok, result} =
               @token_module.build_claims(GuardianImpl, @user, "1", %{}, ttl: {1, :day})

      diff = Guardian.timestamp() + 1 * 24 * 60 * 60 - result["exp"]
      assert diff <= 1
    end
  end

  describe "verify_claims" do
    test "it returns the claims" do
      assert {:ok, @claims} = @token_module.verify_claims(GuardianImpl, @claims, [])
    end

    test "verifies 'exp'" do
      claims = %{
        "exp" => nil
      }

      assert {:ok, _claims} = @token_module.verify_claims(GuardianImpl, claims, [])

      claims = %{
        "exp" => Guardian.timestamp() + 5
      }

      assert {:ok, _claims} = @token_module.verify_claims(GuardianImpl, claims, [])

      claims = %{
        "exp" => Guardian.timestamp() - 1
      }

      assert {:error, :token_expired} = @token_module.verify_claims(GuardianImpl, claims, [])
    end
  end

  describe "refresh" do
    test "returns an error" do
      assert {:error, :not_applicable} = @token_module.refresh(GuardianImpl, @token_id, [])
    end
  end

  describe "exchange" do
    test "returns an error" do
      assert {:error, :not_applicable} =
               @token_module.exchange(GuardianImpl, @token_id, "access", "refresh", [])
    end
  end
end
