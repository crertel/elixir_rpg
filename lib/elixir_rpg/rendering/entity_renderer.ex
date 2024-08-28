defmodule ElixirRpg.Render.EntityRenderer do
  alias Graphmath.Vec2, as: V

  def render({brain, state}) do
    {defs, markup} = brain.render(state)
    {0,
    defs,
    markup}
  end
end
