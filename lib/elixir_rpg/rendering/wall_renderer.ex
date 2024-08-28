defmodule ElixirRpg.Render.WallRenderer do
  alias Graphmath.Vec2, as: V

  def render({idx, {_startX, _startY} = s, {_endX, _endY} = e, thickness, texture, ix, iy}) do
    # This is done to give thickness to the walls so that they miter properly...at least for right angles.
    line_dir = V.subtract(e, s) |> V.normalize()
    cross = V.perp(line_dir) |> V.scale(0.5 * thickness)
    s = V.subtract(s, V.scale(line_dir, 0.5 * thickness))
    e = V.add(e, V.scale(line_dir, 0.5 * thickness))

    points =
      [
        V.add(s, cross),
        V.add(e, cross),
        V.subtract(e, cross),
        V.subtract(s, cross)
      ]
      |> Enum.map(fn {x, y} -> "#{x},#{y}" end)
      |> Enum.join(" ")

    {idx, %{points: points, ix: ix, iy: iy, texture: texture}}
  end
end
