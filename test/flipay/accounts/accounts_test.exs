defmodule Flipay.AccountsTest do
  use Flipay.DataCase

  alias Flipay.Accounts

  describe "users" do
    alias Flipay.Accounts.User

    @valid_attrs %{
      email: "some@email",
      password: "some_password",
      password_confirmation: "some_password"
    }
    @update_attrs %{
      email: "some@updated.email",
      password: "some_updated_password",
      password_confirmation: "some_updated_password"
    }
    @invalid_attrs %{email: nil, password: nil, password_confirmation: nil}
    def user_fixture(attrs \\ %{}) do
      {:ok, user} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Accounts.create_user()

      user
    end

    test "list_users/0 returns all users" do
      user = user_fixture()
      [actual_user] = Accounts.list_users()
      assert actual_user.email == user.email
      assert actual_user.inserted_at == user.inserted_at
      assert actual_user.password_hash == user.password_hash
      assert actual_user.updated_at == user.updated_at
    end

    test "get_user!/1 returns the user with given id" do
      user = user_fixture()
      actual_user = Accounts.get_user!(user.id)
      assert actual_user.email == user.email
      assert actual_user.inserted_at == user.inserted_at
      assert actual_user.password_hash == user.password_hash
      assert actual_user.updated_at == user.updated_at
    end

    test "create_user/1 with valid data creates a user" do
      assert {:ok, %User{} = user} = Accounts.create_user(@valid_attrs)
      assert user.email == "some@email"
    end

    test "create_user/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_user(@invalid_attrs)
    end

    test "update_user/2 with valid data updates the user" do
      user = user_fixture()
      assert {:ok, %User{} = user} = Accounts.update_user(user, @update_attrs)
      assert user.email == "some@updated.email"
    end

    test "update_user/2 with invalid data returns error changeset" do
      user = user_fixture()
      assert {:error, %Ecto.Changeset{}} = Accounts.update_user(user, @invalid_attrs)
      actual_user = Accounts.get_user!(user.id)
      assert actual_user.email == user.email
      assert actual_user.inserted_at == user.inserted_at
      assert actual_user.password_hash == user.password_hash
      assert actual_user.updated_at == user.updated_at
    end

    test "delete_user/1 deletes the user" do
      user = user_fixture()
      assert {:ok, %User{}} = Accounts.delete_user(user)
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_user!(user.id) end
    end

    test "change_user/1 returns a user changeset" do
      user = user_fixture()
      assert %Ecto.Changeset{} = Accounts.change_user(user)
    end

    test "token_sign_in/2 returns user resource" do
      user = user_fixture()
      assert {:ok, token, user_resource} = Accounts.token_sign_in(user.email, user.password)
      assert user_resource["sub"] == to_string(user.id)
    end

    test "token_sign_in/2 returns unauthorized error" do
      user = user_fixture()
      assert {:error, :unauthorized} = Accounts.token_sign_in(user.email, "wrong_password")
    end
  end
end
