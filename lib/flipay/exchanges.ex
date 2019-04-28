defmodule Flipay.Exchanges do
  @moduledoc """
  Get order book from specific exchange, according to input/output assets.
  """
  alias Flipay.Exchanges.Quote
  alias Flipay.Exchanges.OrderBook

  @asks "asks"
  @bids "bids"

  @doc """
  Get quotes by specific exchange name and input/output assets.

  ## Examples:

      iex> input = %{exchange_name: "coinbase", input_asset: "USD", output_asset: "BTC"}
      iex> {:ok, order_book} = Flipay.Exchanges.get_quotes(input)
      iex> Enum.count(order_book.quotes) > 0
      true
      iex> input = %{input | exchange_name: "hitbtc"}
      iex> Flipay.Exchanges.get_quotes(input)
      {:error, :not_found}
      iex> input = %{input | exchange_name: "coinbase", output_asset: "TWD"}
      iex> Flipay.Exchanges.get_quotes(input)
      {:error, :unsupported_asset}

  """
  def get_quotes(%{
        exchange_name: exchange_name,
        input_asset: input_asset,
        output_asset: output_asset
      }) do
    with {:ok, order_book} <- get_exchange(exchange_name),
         {:ok, order_book} <- set_assets(order_book, input_asset, output_asset),
         {:ok, order_book} <- get_order_book(order_book) do
      {:ok, order_book |> convert_to_decimal() |> sort_quotes()}
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
        asset: nil,
        quotes: [%{price: 4900}, %{price: 5000}, %{price: 5100}]
      }
      iex> order_book = %Flipay.Exchanges.OrderBook{order_book | exchange_side: "bids"}
      iex> Flipay.Exchanges.sort_quotes(order_book)
      %Flipay.Exchanges.OrderBook{
        exchange: nil,
        exchange_side: "bids",
        asset: nil,
        quotes: [%{price: 5100}, %{price: 5000}, %{price: 4900}]
      }

  """
  def sort_quotes(%OrderBook{quotes: quotes, exchange_side: exchange_side} = order_book) do
    case exchange_side do
      @asks ->
        %OrderBook{order_book | quotes: Enum.sort(quotes, fn x, y -> x.price < y.price end)}

      @bids ->
        %OrderBook{order_book | quotes: Enum.sort(quotes, fn x, y -> x.price > y.price end)}
    end
  end

  @doc """
  Gets quotes from order books by specific exchange side.

  ## Examples

      iex> input = %Flipay.Exchanges.OrderBook{quotes: %{ "5000" => "2" }}
      iex> order_book = Flipay.Exchanges.convert_to_decimal(input)
      iex> {:ok, quote} = Enum.fetch(order_book.quotes,0)
      iex> quote.price
      #Decimal<5000>
      iex> quote.size
      #Decimal<2>

  """
  def convert_to_decimal(%OrderBook{quotes: quotes} = order_book) do
    filtered_quotes =
      Enum.map(quotes, fn {key, value} ->
        {_, price} = Decimal.parse(key)
        {_, size} = Decimal.parse(value)
        %Quote{price: price, size: size}
      end)

    %OrderBook{order_book | quotes: filtered_quotes}
  end

  @doc """
  Get order books from exchange.

  ## Examples:

      iex> order_book = %Flipay.Exchanges.OrderBook{exchange: Flipay.Exchanges.Coinbase, asset: "BTC-USD", exchange_side: "asks"}
      iex> {:ok, order_book} = Flipay.Exchanges.get_order_book(order_book)
      iex> map_size(order_book.quotes) > 0
      true

  """
  def get_order_book(
        %OrderBook{exchange: exchange, asset: asset, exchange_side: exchange_side} = order_book
      ) do
    with {:ok, result} <- exchange.get_order_book(asset, exchange_side) do
      {:ok, %OrderBook{order_book | quotes: result}}
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
        asset: "BTC-USD",
        exchange_side: "asks",
        quotes: nil
      }}
      iex> Flipay.Exchanges.set_assets(order_book, "ETH", "USD")
      {:ok,
      %Flipay.Exchanges.OrderBook{
        exchange: nil,
        asset: "ETH-USD",
        exchange_side: "bids",
        quotes: nil
      }}
      iex> Flipay.Exchanges.set_assets(order_book, "ETH", "TWD")
      {:error, :unsupported_asset}
      iex> Flipay.Exchanges.set_assets(order_book, "TWD", "USD")
      {:error, :unsupported_asset}

  """
  def set_assets(order_book, input_asset, output_asset) do
    with {:ok, input_asset_type} <- get_asset_type(input_asset),
         {:ok, output_asset_type} <- get_asset_type(output_asset) do
      case {input_asset_type, output_asset_type} do
        {:fiat_money, :digital_currency} ->
          {:ok,
           %OrderBook{order_book | asset: "#{output_asset}-#{input_asset}", exchange_side: @asks}}

        {:digital_currency, :fiat_money} ->
          {:ok,
           %OrderBook{order_book | asset: "#{input_asset}-#{output_asset}", exchange_side: @bids}}
      end
    end
  end

  @doc """
  Gets the type of specific asset.

  ## Examples

      iex> Flipay.Exchanges.get_asset_type("TWD")
      {:error, :unsupported_asset}

      iex> Flipay.Exchanges.get_asset_type("USD")
      {:ok, :fiat_money}

      iex(3)> Flipay.Exchanges.get_asset_type("BTC")
      {:ok, :digital_currency}

  """
  def get_asset_type(asset) when asset in ["USD"], do: {:ok, :fiat_money}
  def get_asset_type(asset) when asset in ["BTC", "ETH"], do: {:ok, :digital_currency}
  def get_asset_type(_), do: {:error, :unsupported_asset}

  @doc """
  Get exchange module by exchange name.

  ## Examples:

      iex> Flipay.Exchanges.get_exchange("coinbase_pro")
      {:ok,
      %Flipay.Exchanges.OrderBook{
        exchange: Flipay.Exchanges.Coinbase,
        exchange_side: nil,
        asset: nil,
        quotes: nil
      }}
      iex> Flipay.Exchanges.get_exchange("hitbtc")
      {:error, :not_found}

  """
  def get_exchange(exchange_name) when exchange_name in ["coinbase_pro", "coinbase"],
    do: {:ok, %OrderBook{exchange: Flipay.Exchanges.Coinbase}}

  def get_exchange(_), do: {:error, :not_found}
end
