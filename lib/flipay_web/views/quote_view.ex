defmodule FlipayWeb.QuoteView do
  @moduledoc """
  View for quote controller.
  """
  use FlipayWeb, :view

  @doc """
  Render success message.
  """
  def render("show.json", %{best_rate: best_rate}) do
    %{best_rate: best_rate}
  end
end
