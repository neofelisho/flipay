defmodule Flipay.Exchanges.Exchange do
  @moduledoc """
  Defint the behaviors that each implementation of exchange should have.
  """

  @doc """
  Get order book by specific asset and exchange_side.
  If success returns {:ok, order_book}, otherwise returns {:error, reason}.
  """
  @callback get_order_book(String.t(), String.t()) :: {atom() ,String.t()}
end
