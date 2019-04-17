defmodule Flipay.Exchanges.Exchange do
  @callback get_order_book(String.t(), String.t()) :: {atom() ,String.t()}
end
