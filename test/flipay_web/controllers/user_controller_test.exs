defmodule FlipayWeb.UserControllerTest do
  use FlipayWeb.ConnCase

  alias Flipay.Accounts

  @create_attrs %{
    email: "some@email",
    password: "some_password",
    password_confirmation: "some_password"
  }
  @invalid_attrs %{email: nil, password: nil, password_confirmation: nil}
  @sign_in_attrs %{email: "some@email", password: "some_password"}

  def fixture(:user) do
    {:ok, user} = Accounts.create_user(@create_attrs)
    user
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "create user" do
    test "renders user when data is valid", %{conn: conn} do
      conn_create = post(conn, Routes.user_path(conn, :create), user: @create_attrs)
      assert %{"jwt" => jwt} = json_response(conn_create, 200)

      conn_sign_in =
        post(conn, Routes.user_path(conn, :sign_in),
          email: @sign_in_attrs.email,
          password: @sign_in_attrs.password
        )

      assert %{"jwt" => jwt} = json_response(conn_sign_in, 200)

      conn_show_user =
        conn
        |> Plug.Conn.put_req_header("authorization", "Bearer #{jwt}")
        |> get(Routes.user_path(conn, :show))

      assert %{"email" => email, "id" => id, "password_hash" => password_hash} =
               json_response(conn_show_user, 200)["data"]

      assert email == @sign_in_attrs.email
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.user_path(conn, :create), user: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end
end
