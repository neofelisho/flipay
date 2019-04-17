defmodule Flipay.BestRateFinder do

  @doc """
  Finds the best rate for input request.

  ## Examples:

    iex> order_book = %Flipay.Exchanges.OrderBook{
    ...>  exchange: Flipay.Exchanges.Coinbase,
    ...>  exchange_side: "asks",
    ...>  input_asset: "USD",
    ...>  output_asset: "BTC",
    ...>  quotes: [
    ...>    %Flipay.Exchanges.Quote{
    ...>      number_of_order: 1,
    ...>      price: 5000,
    ...>      size: 2
    ...>      },
    ...>    %Flipay.Exchanges.Quote{
    ...>      number_of_order: 1,
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
      Enum.count(order_book.quotes) == 0 -> {:error, "no quotes from exchange"}
      order_book.exchange_side == "asks" -> buy_best_rate(order_book.quotes, input_amount, 0)
      order_book.exchange_side == "bids" -> sell_best_rate(order_book.quotes, input_amount, 0)
      true -> {:error, "unexpected exception"}
    end
  end

  @doc """
  Calculates the best selling rate according to quotes and input size.

  ## Examples:

    iex> quotes = [%Flipay.Exchanges.Quote{number_of_order: 1, price: 5000, size: 1}, %Flipay.Exchanges.Quote{number_of_order: 2, price: 4900, size: 1}]
    iex> {:ok, amount} = Flipay.BestRateFinder.sell_best_rate(quotes, 1, 0)
    iex> amount
    #Decimal<5000>
    iex> {:ok, input_size} = Decimal.parse("1.5")
    iex> {:ok, amount} = Flipay.BestRateFinder.sell_best_rate(quotes, input_size, 0)
    iex> amount
    #Decimal<7450.0>
    iex> {:ok, input_size} = Decimal.parse("3.1")
    iex> Flipay.BestRateFinder.sell_best_rate(quotes, input_size, 0)
    {:error, "not enough orders for trading"}

  """
  def sell_best_rate(quotes, remain_size, total_amount) do
    current_quote = Enum.fetch!(quotes, 0)

    current_size = Decimal.mult(current_quote.size, current_quote.number_of_order)

    cond do
      Decimal.cmp(remain_size, current_size) == :lt ||
          Decimal.cmp(remain_size, current_size) == :eq ->
        {:ok, Decimal.add(total_amount, Decimal.mult(remain_size, current_quote.price))}

      Enum.count(quotes) == 1 ->
        {:error, "not enough orders for trading"}

      true ->
        sell_best_rate(
          Enum.slice(quotes, 1, Enum.count(quotes) - 1),
          Decimal.sub(remain_size, current_size),
          Decimal.add(total_amount, Decimal.mult(current_size, current_quote.price))
        )
    end
  end

  @doc """
  Calculates the best buying rate according to quotes and input amount.

  ## Examples

    iex> order_books = [%Flipay.Exchanges.Quote{number_of_order: 1, price: 5000, size: 1}, %Flipay.Exchanges.Quote{number_of_order: 2, price: 5100, size: 1}]
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
    {:error, "not enough orders for trading"}

  """
  def buy_best_rate(order_books, remain_amount, total_size) do
    current_order = Enum.fetch!(order_books, 0)

    current_amount =
      current_order.number_of_order
      |> Decimal.mult(current_order.price)
      |> Decimal.mult(current_order.size)

    cond do
      Decimal.cmp(remain_amount, current_amount) == :lt ||
          Decimal.cmp(remain_amount, current_amount) == :eq ->
        {:ok, Decimal.add(total_size, Decimal.div(remain_amount, current_order.price))}

      Enum.count(order_books) == 1 ->
        {:error, "not enough orders for trading"}

      true ->
        buy_best_rate(
          Enum.slice(order_books, 1, Enum.count(order_books) - 1),
          Decimal.sub(remain_amount, current_amount),
          Decimal.add(total_size, Decimal.mult(current_order.number_of_order, current_order.size))
        )
    end
  end
end
