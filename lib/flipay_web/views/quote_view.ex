defmodule FlipayWeb.QuoteView do
  use FlipayWeb, :view

  def render("show.json", %{best_rate: best_rate}) do
    %{best_rate: best_rate}
  end
end
