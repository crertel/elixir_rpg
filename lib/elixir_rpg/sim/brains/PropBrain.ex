defmodule ElixirRpg.Brains.PropBrain do
  import ElixirRpg.Util.Math

  def update(_cell, state, _messages, dt) do
    # we're a prop, we don't do anything, really
    {state, []}
  end
end
