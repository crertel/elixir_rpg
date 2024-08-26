defmodule ElixirRpg.Render.WallRenderer do
  alias Graphmath.Vec2, as: V

  def render({{_startX, _startY} = s, {_endX, _endY} = e, thickness, texture, ix, iy}) do
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

    {"""
     <pattern id="texture-#{texture}" patternUnits="userSpaceOnUse" width="#{ix}" height="#{iy}"  patternTransform="scale(0.0078125 0.0078125)">
       <image xlink:href="#{texture}" width="#{ix}" height="#{iy}" />
     </pattern>
     """,
     """
     <polygon points="#{points}" fill="url(#texture-#{texture})" stroke="none"/>
     """}
  end
end
