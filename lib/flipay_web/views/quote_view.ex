defmodule FlipayWeb.QuoteView do
  @moduledoc """
  View for quote controller.
  """
  use FlipayWeb, :view

  @doc """
  Render success message.
  """
  def render("show.json", %{data: data}) do
    %{data: data, timestamp: DateTime.to_unix(DateTime.utc_now(), :millisecond)}
  end
end
