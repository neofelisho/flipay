defmodule FlipayWeb.FallbackController do
  @moduledoc """
  Translates controller action results into valid `Plug.Conn` responses.

  See `Phoenix.Controller.action_fallback/1` for more details.
  """
  use FlipayWeb, :controller

  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(FlipayWeb.ChangesetView)
    |> render("error.json", changeset: changeset)
  end

  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> put_view(FlipayWeb.ErrorView)
    |> render(:"404")
  end

  def call(conn, {:error, :unauthorized}) do
    conn
    |> put_status(:unauthorized)
    |> json(%{error: "Login failed"})
  end

  def call(conn, {:error, :unsupported_asset}) do
    conn
    |> json(%{error: "unsupported asset type"})
    |> render("error.json")
  end

  def call(conn, {:error, :no_quotes}) do
    conn
    |> json(%{error: "no quotes from exchange"})
    |> render("error.json")
  end

  def call(conn, {:error, :not_enough_quotes}) do
    conn
    |> json(%{error: "not enough quotes for trading"})
    |> render("error.json")
  end

  def call(conn, {:error, :unexpected}) do
    conn
    |> json(%{error: "unexpected error"})
    |> render(:"500")
  end
end
