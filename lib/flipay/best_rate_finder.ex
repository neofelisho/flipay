defmodule Flipay.BestRateFinder do
  @moduledoc """
  Find the best rate according to input/output assets, input amount and exchange's order book.
  """

  @doc """
  Finds the best rate for input request.
  Order book comes from specific exchange and the quotes are sorted by best to worst order.
  Input/output assets and input amount are specified by user.

  ## Examples:

      iex> order_book = %Flipay.Exchanges.OrderBook{
      ...>  exchange: Flipay.Exchanges.Coinbase,
      ...>  exchange_side: "asks",
      ...>  asset: "BTC-USD",
      ...>  quotes: [
      ...>    %Flipay.Exchanges.Quote{
      ...>      price: 5000,
      ...>      size: 2
      ...>      },
      ...>    %Flipay.Exchanges.Quote{
      ...>      price: 6000,
      ...>      size: 1
      ...>    }
      ...>  ]
      ...>}
      iex> {:ok, rate} = Flipay.BestRateFinder.find(%{order_book: order_book, input_amount: 12000})
      iex> rate
      #Decimal<2.333333333333333333333333333>

  """
  def find(%{order_book: order_book, input_amount: input_amount}) do
    cond do
      Enum.count(order_book.quotes) == 0 -> {:error, :no_quotes}
      order_book.exchange_side == "asks" -> buy_best_rate(order_book.quotes, input_amount, 0)
      order_book.exchange_side == "bids" -> sell_best_rate(order_book.quotes, input_amount, 0)
      true -> {:error, :unexpected}
    end
  end

  @doc """
  Calculates the best selling rate according to quotes and input size.

  ## Examples:

      iex> quotes = [%Flipay.Exchanges.Quote{price: 5000, size: 1}, %Flipay.Exchanges.Quote{price: 4900, size: 2}]
      iex> {:ok, amount} = Flipay.BestRateFinder.sell_best_rate(quotes, 1, 0)
      iex> amount
      #Decimal<5000>
      iex> {:ok, input_size} = Decimal.parse("1.5")
      iex> {:ok, amount} = Flipay.BestRateFinder.sell_best_rate(quotes, input_size, 0)
      iex> amount
      #Decimal<7450.0>
      iex> {:ok, input_size} = Decimal.parse("3.1")
      iex> Flipay.BestRateFinder.sell_best_rate(quotes, input_size, 0)
      {:error, :not_enough_quotes}

  """
  def sell_best_rate([] = _quotes, _, _), do: {:error, :not_enough_quotes}

  def sell_best_rate([current | rest] = _quotes, remain_size, total_amount) do
    case Decimal.cmp(remain_size, current.size) do
      :gt ->
        sell_best_rate(
          rest,
          Decimal.sub(remain_size, current.size),
          Decimal.add(total_amount, Decimal.mult(current.size, current.price))
        )

      _ ->
        {:ok, Decimal.add(total_amount, Decimal.mult(remain_size, current.price))}
    end
  end

  @doc """
  Calculates the best buying rate according to quotes and input amount.

  ## Examples

      iex> order_books = [%Flipay.Exchanges.Quote{price: 5000, size: 1}, %Flipay.Exchanges.Quote{price: 5100, size: 2}]
      iex> {:ok, size} = Flipay.BestRateFinder.buy_best_rate(order_books, 10100, 0)
      iex> size
      #Decimal<2>
      iex> {:ok, size} = Flipay.BestRateFinder.buy_best_rate(order_books, 15200, 0)
      iex> size
      #Decimal<3>
      iex> {:ok, size} = Flipay.BestRateFinder.buy_best_rate(order_books, 15000, 0)
      iex> size
      #Decimal<2.960784313725490196078431373>
      iex> Flipay.BestRateFinder.buy_best_rate(order_books, 16000, 0)
      {:error, :not_enough_quotes}

  """
  def buy_best_rate([] = _quotes, _, _), do: {:error, :not_enough_quotes}

  def buy_best_rate([current | rest] = _quotes, remain_amount, total_size) do
    current_amount = Decimal.mult(current.price, current.size)

    case Decimal.cmp(remain_amount, current_amount) do
      :gt ->
        buy_best_rate(
          rest,
          Decimal.sub(remain_amount, current_amount),
          Decimal.add(total_size, current.size)
        )

      _ ->
        {:ok, Decimal.add(total_size, Decimal.div(remain_amount, current.price))}
    end
  end
end
