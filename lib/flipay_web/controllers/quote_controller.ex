defmodule FlipayWeb.QuoteController do
  @moduledoc """
  Handle request about asset quotes.
  """
  use FlipayWeb, :controller

  alias Flipay.Exchanges
  alias Flipay.BestRateFinder

  action_fallback FlipayWeb.FallbackController

  @doc """
  Calculate best rate according to input/output assets, input amount and specific exchange.
  """
  def show(
        %Plug.Conn{
          query_params: %{
            "input_asset" => input_asset,
            "input_amount" => input_amount_string,
            "output_asset" => output_asset
          }
        } = conn,
        %{"exchange_name" => exchange_name}
      ) do
    with {:ok, order_book} <-
           Exchanges.get_quotes(%{
             exchange_name: exchange_name,
             input_asset: input_asset,
             output_asset: output_asset
           }),
         {:ok, input_amount} <- Decimal.parse(input_amount_string),
         {:ok, result} <-
           BestRateFinder.find(%{order_book: order_book, input_amount: input_amount}) do
      render(conn, "show.json", best_rate: result)
    end
  end
end
