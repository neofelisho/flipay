defmodule FlipayWeb.UserView do
  @moduledoc """
  View for user controller.
  """
  use FlipayWeb, :view
  alias FlipayWeb.UserView

  # def render("index.json", %{users: users}) do
  #   %{data: render_many(users, UserView, "user.json")}
  # end

  @doc """
  Render show user message.
  """
  def render("show.json", %{user: user}) do
    %{data: render_one(user, UserView, "user.json")}
  end

  @doc """
  Render create user message.
  """
  def render("user.json", %{user: user}) do
    %{id: user.id, email: user.email, password_hash: user.password_hash}
  end

  @doc """
  Render token message.
  """
  def render("jwt.json", %{jwt: jwt}) do
    %{jwt: jwt}
  end
end
