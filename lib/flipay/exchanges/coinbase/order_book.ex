defmodule Flipay.Exchanges.Coinbase.OrderBook do
  @moduledoc """
  Keep order book from Coinbase.
  """
  use Agent

  @asks "asks"
  @bids "bids"
  @assets ["BTC-USD", "ETH-USD"]

  @doc """
  Start a agent to keep state, here is the order book from Coinbase.
  """
  def start_link([]) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  @doc """
  Stop this agent.
  """
  def dispose() do
    Agent.stop(__MODULE__)
  end

  @doc """
  Update market data with new snapshot (discard old data).
  """
  def update_snapshot(
        %{"product_id" => asset, @asks => asks_market_data, @bids => bids_market_data} = _snapshot
      )
      when asset in @assets do
    Agent.update(__MODULE__, fn book ->
      put_in(book, [asset], %{
        @asks => get_market_map(asks_market_data),
        @bids => get_market_map(bids_market_data)
      })
    end)
  end

  def update_snapshot(_snapshot), do: {:error, :unsupported_asset}

  defp get_market_map(market_data) when is_list(market_data) do
    market_data
    |> Enum.map(fn [price, size | _] -> {price, size} end)
    |> Map.new()
  end

  defp get_market_map(_), do: %{}

  @doc """
  Update changes by given asset, side and price.
  """
  def update_level(%{"changes" => changes, "product_id" => asset, "time" => _time} = _level)
      when asset in @assets and is_list(changes),
      do: update_changes(asset, changes)

  def update_level(_level), do: {:error, :unsupported_asset}

  defp update_changes(asset, [[side, price, size | []] = _change | []]),
    do: update_entry(asset, side, price, size)

  defp update_changes(asset, [[side, price, size | []] = _change | rest]) do
    update_entry(asset, side, price, size)
    update_changes(asset, rest)
  end

  defp update_entry(asset, side, price, "0" = _size) do
    Agent.update(__MODULE__, fn book ->
      pop_in(book, [asset, get_exchange_side(side), price]) |> elem(1)
    end)
  end

  defp update_entry(asset, side, price, size) do
    Agent.update(__MODULE__, fn book ->
      put_in(book, [asset, get_exchange_side(side), price], size)
    end)
  end

  defp get_exchange_side("sell"), do: @asks

  defp get_exchange_side("buy"), do: @bids

  @doc """
  Get market data by specific asset and exchange side.
  """
  def get(asset, side) when asset in @assets and side in [@asks, @bids] do
    {:ok,
     Agent.get(__MODULE__, fn book ->
       book
       |> Map.get(asset, %{@asks => %{}, @bids => %{}})
       |> Map.get(side)
     end)}
  end

  def get(_asset, side) when side in [@asks, @bids],
    do: {:error, :unsupported_asset}

  def get(asset, _side) when asset in @assets,
    do: {:error, :unsupported_exchange_side}
end
