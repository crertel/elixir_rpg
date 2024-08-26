defmodule ElixirRpg.Render.FlatRenderer do
  alias Graphmath.Vec2, as: V

  def render({points, texture, ix, iy}) do
    svg_points =
      points
      |> Enum.map(fn {x, y} -> "#{x},#{y}" end)
      |> Enum.join(" ")

    {"""
     <pattern id="texture-#{texture}" patternUnits="userSpaceOnUse" width="#{ix}" height="#{iy}"  patternTransform="scale(0.0078125 0.0078125)">
       <image xlink:href="#{texture}" width="#{ix}" height="#{iy}" />
     </pattern>
     """,
     """
     <polygon points="#{svg_points}" fill="url(#texture-#{texture})" stroke="none"/>
     """}
  end
end
