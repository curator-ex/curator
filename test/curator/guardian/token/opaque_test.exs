defmodule Curator.Guardian.Token.OpaqueTest do
  @moduledoc false

  use ExUnit.Case, async: true

  @token_module Curator.Guardian.Token.Opaque

  defmodule Token do
    use Ecto.Schema
    import Ecto.Changeset

    schema "auth_tokens" do
      field :claims, :map
      field :description, :string
      field :token, :string
      field :user_id, :integer

      timestamps()
    end

    @doc false
    def changeset(token, attrs) do
      token
      |> cast(attrs, [:token, :description, :claims, :user_id])
      |> validate_required([:token, :claims, :user_id])
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
    }

    def insert(changeset) do
      token = changeset
      |> Ecto.Changeset.apply_changes()

      if Map.get(token.claims, :error) do
        {:error, :invalid}
      else
        token = token
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
      token_module: Curator.Guardian.Token.Opaque

    alias Curator.Guardian.Token.OpaqueTest.Auth

    def subject_for_token(user, _claims) do
      sub = to_string(user.id)
      {:ok, sub}
    end

    def resource_from_claims(claims) do
      claims["sub"]
      |> get_user()
    end

    @behaviour Curator.Guardian.Token.Opaque.Persistence

    def get_token(id) do
      Auth.get_token(id)
    end

    def create_token(claims) do
      user_id = Map.get(claims, "user_id") || Map.get(claims, "sub")
      description = Map.get(claims, "description")

      claims = claims
      |> Map.drop(["user_id", "description"])

      token = Curator.Guardian.Token.Opaque.token_id()

      attrs = %{
        "claims" => claims,
        "user_id" => user_id,
        "description" => description,
        "token" => token,
      }

      Auth.create_token(attrs)
    end

    def delete_token(id) do
      case get_token(id) do
        {:ok, token} ->
          Auth.delete_token(token)
        result ->
          result
      end
    end

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
    test "with a nil token"  do
      result = @token_module.peek(GuardianImpl, nil)

      assert result == nil
    end

    test "with a valid token"  do
      result = @token_module.peek(GuardianImpl, @token_id)

      assert result == nil
    end

    test "with an invalid token"  do
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

    test "sets to the default for the token type" do
      assert {:ok, result} = @token_module.build_claims(GuardianImpl, @user, "1", %{})
      assert result["typ"] == "access"

      assert {:ok, result} = @token_module.build_claims(GuardianImpl, @user, "1", %{}, token_type: "refresh")
      assert result["typ"] == "refresh"
    end
  end

  describe "verify_claims" do
    test "it returns the claims" do
      assert {:ok, @claims} = @token_module.verify_claims(GuardianImpl, @claims, [])
    end
  end

  describe "refresh" do
    test "returns an error" do
      assert {:error, :not_applicable} = @token_module.refresh(GuardianImpl, @token_id, [])
    end
  end

  describe "exchange" do
    test "returns an error" do
      assert {:error, :not_applicable} = @token_module.exchange(GuardianImpl, @token_id, "access", "refresh", [])
    end
  end
end
