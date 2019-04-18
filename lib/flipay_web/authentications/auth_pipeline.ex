defmodule FlipayWeb.Authentications.AuthPipeline do
  @moduledoc """
  Authentication pipeline.
  """
  use Guardian.Plug.Pipeline,
    otp_app: :flipay,
    module: Flipay.Guardian,
    error_handler: FlipayWeb.Authentications.AuthErrorHandler

  plug Guardian.Plug.VerifyHeader, realm: "Bearer"
  plug Guardian.Plug.EnsureAuthenticated
  plug Guardian.Plug.LoadResource
end
