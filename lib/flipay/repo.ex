defmodule Flipay.Repo do
  use Ecto.Repo,
    otp_app: :flipay,
    adapter: Ecto.Adapters.Postgres
end
