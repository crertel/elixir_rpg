defmodule ElixirRpg.Render.EntityRenderer do
  alias Graphmath.Vec2, as: V

  def render(%{pos: {x, y}, bounds: {bx, by}, a: theta, img: img} = _state) do
    {0, %{x: x, y: y, bx: bx, by: by, theta: theta, img: img}}
  end
end
