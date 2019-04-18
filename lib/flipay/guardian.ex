defmodule Flipay.Guardian do
  @moduledoc false
  use Guardian, otp_app: :flipay

  def subject_for_token(user, _claims) do
    sub = to_string(user.id)
    {:ok, sub}
  end

  def resource_from_claims(claims) do
    id = claims["sub"]
    resource = Flipay.Accounts.get_user!(id)
    {:ok, resource}
  end
end
