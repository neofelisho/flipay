defmodule FlipayWeb.Authentications.AuthErrorHandler do
  @moduledoc """
  Authentication error handler.
  """
  import Plug.Conn

  @doc """
  Process authentication error.
  """
  def auth_error(conn, {type, _reason}, _opts) do
    body = Jason.encode!(%{error: to_string(type)})

    send_resp(conn, 401, body)
  end
end
