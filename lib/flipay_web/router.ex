defmodule FlipayWeb.Router do
  use FlipayWeb, :router
  alias FlipayWeb.Authentications

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :jwt_authenticated do
    plug Authentications.AuthPipeline
  end

  scope "/api/v1", FlipayWeb do
    pipe_through :api

    post "/sign_up", UserController, :create
    post "/sign_in", UserController, :sign_in
  end

  scope "/api/v1", FlipayWeb do
    pipe_through [:api, :jwt_authenticated]

    get "/my_user", UserController, :show
    get "/quote/:exchange_name", QuoteController, :show
  end
end
