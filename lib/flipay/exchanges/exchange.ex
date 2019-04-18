defmodule Flipay.Exchanges.Exchange do
  @moduledoc """
  Behaviors each exchange implementation should have.
  """

  @doc """
  Get order book by specific input/output assets.
  If success returns {:ok, order book}, otherwise returns {:error, reason}.
  """
  @callback get_order_book(String.t(), String.t()) :: {atom() ,String.t()}
end
