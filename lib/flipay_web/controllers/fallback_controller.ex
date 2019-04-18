defmodule FlipayWeb.FallbackController do
  @moduledoc """
  Translates controller action results into valid `Plug.Conn` responses.

  See `Phoenix.Controller.action_fallback/1` for more details.
  """
  use FlipayWeb, :controller

  @doc """
  Error for ecto changeset.
  """
  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(FlipayWeb.ChangesetView)
    |> render("error.json", changeset: changeset)
  end

  @doc """
  Error for 404 not found.
  """
  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> put_view(FlipayWeb.ErrorView)
    |> render(:"404")
  end

  @doc """
  Error for unauthorized.
  """
  def call(conn, {:error, :unauthorized}) do
    conn
    |> put_status(:unauthorized)
    |> json(%{error: "Login failed"})
  end

  @doc """
  Error for unsupported asset.
  """
  def call(conn, {:error, :unsupported_asset}) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "unsupported asset type"})
  end

  @doc """
  Error for no quotes from exchange.
  """
  def call(conn, {:error, :no_quotes}) do
    conn
    |> put_status(:ok)
    |> json(%{error: "no quotes from exchange"})
  end

  @doc """
  Error for not enough quotes from exchange (input amount too large).
  """
  def call(conn, {:error, :not_enough_quotes}) do
    conn
    |> put_status(:ok)
    |> json(%{error: "not enough quotes for trading"})
  end

  @doc """
  Error for unexpected situation.
  """
  def call(conn, {:error, :unexpected}) do
    conn
    |> put_status(:internal_server_error)
    |> json(%{error: "unexpected error"})
  end
end
