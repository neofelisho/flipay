defmodule Flipay.Exchanges.Coinbase do
  @moduledoc """
  Implementation of exchange: Coinbase.
  Currently here is a mock version.
  """
  @behaviour Flipay.Exchanges.Exchange

  @doc """
  Get order book according to input/output assets.

  ## Examples:

      iex> get_order_book("USD", "BTC")
      {:ok, ~s(
        {
          "bids": [
            ["4000", "10", "1"],
            ["3900", "1", "1"]
          ],
          "asks": [
            ["5000", "2", "1"],
            ["6000", "1", "1"]
          ]
        }
      )}
  """
  def get_order_book(_input_asset, _output_asset) do
    {:ok, ~s(
      {
        "bids": [
          ["4000", "10", "1"],
          ["3900", "1", "1"]
        ],
        "asks": [
          ["5000", "2", "1"],
          ["6000", "1", "1"]
        ]
      }
    )}
  end
end
