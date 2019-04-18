defmodule Flipay.Repo do
  @moduledoc false
  use Ecto.Repo,
    otp_app: :flipay,
    adapter: Ecto.Adapters.Postgres
end
