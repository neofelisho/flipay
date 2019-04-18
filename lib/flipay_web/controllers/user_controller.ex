defmodule FlipayWeb.UserController do
  @moduledoc """
  Handle request about user account and authentication.
  """
  use FlipayWeb, :controller

  alias Flipay.Accounts
  alias Flipay.Accounts.User
  alias Flipay.Guardian

  action_fallback FlipayWeb.FallbackController

  @doc """
  Create user account.
  """
  def create(conn, %{"user" => user_params}) do
    with {:ok, %User{} = user} <- Accounts.create_user(user_params),
         {:ok, token, _claims} <- Guardian.encode_and_sign(user) do
      conn
      |> render("jwt.json", jwt: token)
    end
  end

  @doc """
  Get user information.
  """
  def show(conn, _params) do
    user = Guardian.Plug.current_resource(conn)
    render(conn, "show.json", user: user)
  end

  @doc """
  Sign in user.
  """
  def sign_in(conn, %{"email" => email, "password" => password}) do
    case Accounts.token_sign_in(email, password) do
      {:ok, token, _claims} -> conn |> render("jwt.json", jwt: token)
      _ -> {:error, :unauthorized}
    end
  end
end
