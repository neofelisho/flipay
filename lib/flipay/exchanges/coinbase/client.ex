defmodule Flipay.Exchanges.Coinbase.Client do
  @moduledoc """
  WebSocket client for [Coinbase](https://www.coinbase.com/).
  Reference the [documentation](https://docs.pro.coinbase.com/#websocket-feed) of Coinbase Pro.
  """
  use WebSockex
  require Logger
  alias Flipay.Exchanges.Coinbase.OrderBook

  @url "wss://ws-feed.pro.coinbase.com"

  @doc """
  Start WebSocket client.
  """
  def start_link(products) do
    {:ok, pid} = WebSockex.start_link(@url, __MODULE__, :no_state)
    subscribe(pid, products)
    {:ok, pid}
  end

  def handle_connect(_conn, state) do
    Logger.info("Connecting to #{@url}")
    {:ok, state}
  end

  def handle_disconnect(_conn, state) do
    Logger.info("Disconnected from #{@url}")
    {:ok, state}
  end

  defp subscribe(pid, products) do
    Logger.info("Subscribe products: #{Enum.join(products, ", ")}")
    WebSockex.send_frame(pid, subscription_frame(products))
  end

  defp subscription_frame(products) do
    subscription_msg =
      %{
        type: "subscribe",
        product_ids: products,
        channels: ["level2"]
      }
      |> Jason.encode!()

    {:text, subscription_msg}
  end

  def handle_frame(_frame = {:text, msg}, state) do
    msg
    |> Jason.decode!()
    |> handle_msg(state)
  end

  defp handle_msg(%{"type" => "snapshot"} = snapshot, state) do
    OrderBook.update_snapshot(snapshot)
    {:ok, state}
  end

  defp handle_msg(%{"type" => "l2update"} = l2update, state) do
    OrderBook.update_level(l2update)
    {:ok, state}
  end

  defp handle_msg(_, state), do: {:ok, state}
end
