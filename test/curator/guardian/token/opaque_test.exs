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
    @token_id "TEST"

    @token %Token{
      token: @token_id,
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
        {:ok, token}
      end
    end

    def get_by(Token, %{token: @token_id}) do
      @token
    end

    def get_by(_mod, _params) do
      nil
    end
  end

  defmodule Auth do
    alias Curator.Guardian.Token.OpaqueTest.Token
    alias Curator.Guardian.Token.OpaqueTest.Repo

    def create_token(attrs \\ %{}) do
      struct(Token, %{})
      |> Token.changeset(attrs)
      |> Repo.insert()
    end

    def delete_token(%Token{} = token) do
      Repo.delete(token)
    end
  end

  defmodule Impl do
    use Guardian,
      otp_app: :curator,
      token_module: Curator.Guardian.Token.Opaque

    alias Curator.Guardian.Token.OpaqueTest.Auth
    alias Curator.Guardian.Token.OpaqueTest.Repo

    def subject_for_token(user, _claims) do
      sub = to_string(user.id)
      {:ok, sub}
    end

    def resource_from_claims(claims) do
      claims["sub"]
      |> get_user()
    end

    @behaviour Curator.Guardian.Token.Opaque.Persistence

    def get_token(token_id) do
      case Repo.get_by(Token, %{token: token_id}) do
        nil ->
          {:error, :not_found}
        token ->
          {:ok, token}
      end
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

    def delete_token(token_id) do
      case Repo.get_by(Token, %{token: token_id}) do
        nil ->
          {:error, :not_found}
        token ->
          Auth.delete_token(token)
      end
    end

    def get_user(1) do
      {:ok, %{id: 1}}
    end

    def get_user(_) do
      {:error, :not_found}
    end
  end

  @token_id "TEST"
  @invalid_token_id "1234"

  @claims %{
    "typ" => "access",
    "sub" => "1",
    "something_else" => "foo"
  }

  describe "peek" do
    test "with a nil token"  do
      result = @token_module.peek(Impl, nil)

      assert result == nil
    end

    test "with a valid token"  do
      result = @token_module.peek(Impl, @token_id)

      assert result == %{
               claims: @claims
             }
    end

    test "with an invalid token"  do
      result = @token_module.peek(Impl, @invalid_token_id)

      assert result == nil
    end
  end

  describe "create_token" do
    test "(when valid) creates a token " do
      {:ok, _token} = @token_module.create_token(Impl, @claims)
    end

     test "(when invalid) returns an error" do
      {:error, :invalid} = @token_module.create_token(Impl, %{error: "invalid"})
    end
  end

  describe "decode_token" do
    test "returns the claims when it exists" do
      {:ok, @claims} = @token_module.decode_token(Impl, @token_id)
    end

    test "returns an error when it doesn't exists" do
      {:error, :not_found} = @token_module.decode_token(Impl, @invalid_token_id)
    end
  end

  describe "build_claims" do
    @user %{id: "1"}

    test "it adds some fields" do
      {:ok, result} = @token_module.build_claims(Impl, @user, "1")

      assert result["typ"] == "access"
      assert result["sub"] == "1"
    end

    test "it keeps other fields that have been added" do
      assert {:ok, result} = @token_module.build_claims(Impl, @user, "1", %{my: "claim"})
      assert result["my"] == "claim"
    end

    test "sets to the default for the token type" do
      assert {:ok, result} = @token_module.build_claims(Impl, @user, "1", %{})
      assert result["typ"] == "access"

      assert {:ok, result} = @token_module.build_claims(Impl, @user, "1", %{}, token_type: "refresh")
      assert result["typ"] == "refresh"
    end
  end

  describe "verify_claims" do
    test "it returns the claims" do
      assert {:ok, @claims} = @token_module.verify_claims(Impl, @claims, [])
    end
  end

  describe "refresh" do
    test "returns an error" do
      assert {:error, :not_applicable} = @token_module.refresh(Impl, @token_id, [])
    end
  end

  describe "exchange" do
    test "returns an error" do
      assert {:error, :not_applicable} = @token_module.exchange(Impl, @token_id, "access", "refresh", [])
    end
  end
end