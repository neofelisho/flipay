defmodule Flipay.Exchanges.Coinbase.OrderBookTest do
  use ExUnit.Case
  alias Flipay.Exchanges.Coinbase.OrderBook

  doctest Flipay.Exchanges.Coinbase.OrderBook

  @asset "BTC-USD"
  @asks "asks"
  @bids "bids"
  @product_id "product_id"
  @asks_market_data1 [["5572.06", "15.88030361"], ["5573.1", "1"]]
  @bids_market_data1 [["5572.05", "0.86399404"], ["5571.52", "0.1"]]
  @asks_market_data2 [["5572.06", "15.73650412"], ["5573.1", "1"]]
  @bids_market_data2 [["5571.52", "0.1"], ["5570.19000000", "3.143"]]

  test "keep state by order book agent" do
    assert :ok =
             OrderBook.update_snapshot(%{
               @product_id => @asset,
               @asks => @asks_market_data1,
               @bids => @bids_market_data1
             })

    assert {:ok, %{"5572.06" => "15.88030361", "5573.1" => "1"}} == OrderBook.get(@asset, @asks)
    assert {:ok, %{"5572.05" => "0.86399404", "5571.52" => "0.1"}} == OrderBook.get(@asset, @bids)

    assert :ok =
             OrderBook.update_snapshot(%{
               @product_id => @asset,
               @asks => @asks_market_data2,
               @bids => @bids_market_data2
             })

    assert {:ok, %{"5572.06" => "15.73650412", "5573.1" => "1"}} == OrderBook.get(@asset, @asks)

    assert {:ok, %{"5571.52" => "0.1", "5570.19000000" => "3.143"}} ==
             OrderBook.get(@asset, @bids)

    assert :ok =
             OrderBook.update_level(%{
               "changes" => [
                 ["buy", "5560.41000000", "0.62678"],
                 ["buy", "5547.55000000", "0.57829622"]
               ],
               "product_id" => "BTC-USD",
               "time" => "2019-04-23T14:20:08.207Z"
             })

    assert {:ok,
            %{
              "5571.52" => "0.1",
              "5570.19000000" => "3.143",
              "5560.41000000" => "0.62678",
              "5547.55000000" => "0.57829622"
            }} = OrderBook.get(@asset, @bids)

    assert :ok = OrderBook.dispose()
  end
end
