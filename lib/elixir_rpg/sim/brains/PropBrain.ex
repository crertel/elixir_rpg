defmodule ElixirRpg.Brains.PropBrain do
  def update(_cell, state, _messages) do
    # we're a prop, we don't do anything, really
    {state, []}
  end

  def render(%{pos: {x, y}, bounds: {bx, by}, a: 0, img: img}) do
  end
end
