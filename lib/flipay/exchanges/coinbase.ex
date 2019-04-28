defmodule Flipay.Exchanges.Coinbase do
  @moduledoc """
  Implementation of exchange: Coinbase.
  Currently here is a mock version.
  """
  @behaviour Flipay.Exchanges.Exchange

  alias Flipay.Exchanges.Coinbase.OrderBook

  @doc """
  Get order book according to input/output assets.

  ## Examples:

      iex> get_order_book("BTC-USD", "asks")
      {:ok, %{"5000" => "2", "6000" => "1"}

  """
  def get_order_book(asset, exchange_side), do: OrderBook.get(asset, exchange_side)
end
