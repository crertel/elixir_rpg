defmodule ElixirRpg.Render.FlatRenderer do
  def render({idx, points, texture, ix, iy}) do
    svg_points =
      points
      |> Enum.map(fn {x, y} -> "#{x},#{y}" end)
      |> Enum.join(" ")

    {idx,
     %{points: svg_points, ix: ix, iy: iy, texture: texture}}
  end
end
