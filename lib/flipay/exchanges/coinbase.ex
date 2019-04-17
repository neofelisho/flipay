defmodule Flipay.Exchanges.Coinbase do
  @behaviour Flipay.Exchanges.Exchange

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
