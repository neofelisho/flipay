defmodule Flipay.Exchanges do
  alias Flipay.Exchanges.Quote
  alias Flipay.Exchanges.OrderBook

  @doc """
  Get quotes by specific exchange name and input/output assets.

  ## Examples:

    iex> input = %{exchange_name: "coinbase", input_asset: "USD", output_asset: "BTC"}
    iex> order_book = Flipay.Exchanges.get_quotes(input)
    iex> {:ok, quote_0} = Enum.fetch(order_book.quotes, 0)
    iex> quote_0.price
    #Decimal<5000>
    iex> quote_0.size
    #Decimal<2>
    iex> {:ok, quote_1} = Enum.fetch(order_book.quotes, 1)
    iex> quote_1.price
    #Decimal<6000>
    iex> quote_1.size
    #Decimal<1>
    iex> input = %{input | exchange_name: "hitbtc"}
    iex> Flipay.Exchanges.get_quotes(input)
    {:error, "not yet implemented"}
    iex> input = %{input | exchange_name: "coinbase", output_asset: "TWD"}
    iex> Flipay.Exchanges.get_quotes(input)
    {:error, "output asset: unsupported asset type"}

  """
  def get_quotes(%{
        exchange_name: exchange_name,
        input_asset: input_asset,
        output_asset: output_asset
      }) do
    with {:ok, order_book} <- get_exchange(exchange_name),
         {:ok, order_book} <- set_assets(order_book, input_asset, output_asset),
         {:ok, order_book} <- get_order_book(order_book) do
      order_book
      |> filter_quotes()
      |> sort_quotes()
    end
  end

  @doc """
  Sorts the quotes by exchange side to make sure the quotes are sorted from best to worst.

  ## Examples:

    iex> order_book = %Flipay.Exchanges.OrderBook{quotes: [%{price: 5000}, %{price: 4900}, %{price: 5100}], exchange_side: "asks"}
    iex> Flipay.Exchanges.sort_quotes(order_book)
    %Flipay.Exchanges.OrderBook{
      exchange: nil,
      exchange_side: "asks",
      input_asset: nil,
      output_asset: nil,
      quotes: [%{price: 4900}, %{price: 5000}, %{price: 5100}]
    }
    iex> order_book = %Flipay.Exchanges.OrderBook{order_book | exchange_side: "bids"}
    iex> Flipay.Exchanges.sort_quotes(order_book)
    %Flipay.Exchanges.OrderBook{
      exchange: nil,
      exchange_side: "bids",
      input_asset: nil,
      output_asset: nil,
      quotes: [%{price: 5100}, %{price: 5000}, %{price: 4900}]
    }

  """
  def sort_quotes(%OrderBook{quotes: quotes, exchange_side: exchange_side} = order_book) do
    case exchange_side do
      "asks" ->
        %OrderBook{order_book | quotes: Enum.sort(quotes, fn x, y -> x.price < y.price end)}

      "bids" ->
        %OrderBook{order_book | quotes: Enum.sort(quotes, fn x, y -> x.price > y.price end)}
    end
  end

  @doc """
  Gets quotes from order books by specific exchange side.

  ## Examples

    iex> input = %Flipay.Exchanges.OrderBook{quotes: %{ "asks" => [["5000", "2", "1"]], "bids" => [["4900", "1", "2"]] }, exchange_side: "asks"}
    iex> order_book = Flipay.Exchanges.filter_quotes(input)
    iex> {:ok, quote} = Enum.fetch(order_book.quotes,0)
    iex> quote.number_of_order
    1
    iex> quote.price
    #Decimal<5000>
    iex> quote.size
    #Decimal<2>

  """
  def filter_quotes(%OrderBook{quotes: quotes, exchange_side: exchange_side} = order_book) do
    filtered_quotes =
      Enum.map(quotes[exchange_side], fn [price_string, size_string, number_of_order_string] ->
        {_, price} = Decimal.parse(price_string)
        {_, size} = Decimal.parse(size_string)
        {number_of_order, _} = Integer.parse(number_of_order_string)
        %Quote{price: price, size: size, number_of_order: number_of_order}
      end)

    %OrderBook{order_book | quotes: filtered_quotes}
  end

  @doc """
  Get order books from exchange.

  ## Examples:

    iex> order_book = %Flipay.Exchanges.OrderBook{exchange: Flipay.Exchanges.Coinbase, input_asset: "USD", output_asset: "BTC"}
    iex> {:ok, order_book} = Flipay.Exchanges.get_order_book(order_book)
    iex> order_book
    %Flipay.Exchanges.OrderBook{
      exchange: Flipay.Exchanges.Coinbase,
      exchange_side: nil,
      input_asset: "USD",
      output_asset: "BTC",
      quotes: %{
        "asks" => [["5000", "2", "1"], ["6000", "1", "1"]],
        "bids" => [["4000", "10", "1"], ["3900", "1", "1"]]
      }
    }

  """
  def get_order_book(
        %OrderBook{exchange: exchange, input_asset: input_asset, output_asset: output_asset} =
          order_book
      ) do
    with {:ok, result} <- exchange.get_order_book(input_asset, output_asset) do
      {:ok, %OrderBook{order_book | quotes: result |> Jason.decode!()}}
    end
  end

  @doc """
  Sets input/output assets and determine the exchange side.

  ## Examples:

    iex> order_book = %Flipay.Exchanges.OrderBook{}
    iex> Flipay.Exchanges.set_assets(order_book, "USD", "BTC")
    {:ok,
    %Flipay.Exchanges.OrderBook{
      exchange: nil,
      exchange_side: "asks",
      input_asset: "USD",
      output_asset: "BTC",
      quotes: nil
    }}
    iex> Flipay.Exchanges.set_assets(order_book, "ETH", "USD")
    {:ok,
    %Flipay.Exchanges.OrderBook{
      exchange: nil,
      exchange_side: "bids",
      input_asset: "ETH",
      output_asset: "USD",
      quotes: nil
    }}
    iex> Flipay.Exchanges.set_assets(order_book, "ETH", "TWD")
    {:error, "output asset: unsupported asset type"}
    iex> Flipay.Exchanges.set_assets(order_book, "TWD", "USD")
    {:error, "input asset: unsupported asset type"}

  """
  def set_assets(order_book, input_asset, output_asset) do
    case {get_asset_type(input_asset), get_asset_type(output_asset)} do
      {:fiat_money, :digital_currency} ->
        {:ok,
         %OrderBook{
           order_book
           | input_asset: input_asset,
             output_asset: output_asset,
             exchange_side: "asks"
         }}

      {:digital_currency, :fiat_money} ->
        {:ok,
         %OrderBook{
           order_book
           | input_asset: input_asset,
             output_asset: output_asset,
             exchange_side: "bids"
         }}

      {{:error, error_msg}, _} ->
        {:error, "input asset: #{error_msg}"}

      {_, {:error, error_msg}} ->
        {:error, "output asset: #{error_msg}"}
    end
  end

  @doc """
  Gets the type of specific asset.

  ## Examples

    iex> Flipay.Exchanges.get_asset_type("TWD")
    {:error, "unsupported asset type"}

    iex> Flipay.Exchanges.get_asset_type("USD")
    :fiat_money

    iex(3)> Flipay.Exchanges.get_asset_type("BTC")
    :digital_currency

  """
  def get_asset_type(asset) do
    fiat_money = ["USD"]
    digital_currencies = ["BTC", "ETH"]

    cond do
      Enum.member?(fiat_money, asset) -> :fiat_money
      Enum.member?(digital_currencies, asset) -> :digital_currency
      true -> {:error, "unsupported asset type"}
    end
  end

  @doc """
  Get exchange module by exchange name.

  ## Examples:

    iex> Flipay.Exchanges.get_exchange("coinbase")
    {:ok,
    %Flipay.Exchanges.OrderBook{
      exchange: Flipay.Exchanges.Coinbase,
      exchange_side: nil,
      input_asset: nil,
      output_asset: nil,
      quotes: nil
    }}
    iex> Flipay.Exchanges.get_exchange("hitbtc")
    {:error, "not yet implemented"}

  """
  def get_exchange(exchange_name) do
    case exchange_name do
      "coinbase" -> {:ok, %OrderBook{exchange: Flipay.Exchanges.Coinbase}}
      _ -> {:error, "not yet implemented"}
    end
  end
end
