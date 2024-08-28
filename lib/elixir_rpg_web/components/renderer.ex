defmodule ElixirRpgWeb.Renderer do
  use Phoenix.Component
  import ElixirRpg.Util.Math

  def flat_pattern(assigns) do
    ~H"""
    <pattern id="texture-#{@texture}" patternUnits="userSpaceOnUse" width="#{@ix}" height="#{@iy}"  patternTransform="scale(0.0078125 0.0078125)">
       <image xlink:href="#{@texture}" width="#{@ix}" height="#{@iy}" />
    </pattern>
    """
  end

  def flat_geo(assigns) do
    ~H"""
    <polygon points="#{@points}" fill="url(#texture-#{@texture})" stroke="none"/>
    """
  end

  def wall_pattern(assigns) do
    ~H"""
     <pattern id="texture-#{@texture}" patternUnits="userSpaceOnUse" width="#{@ix}" height="#{@iy}"  patternTransform="scale(0.0078125 0.0078125)">
       <image xlink:href="#{@texture}" width="#{@ix}" height="#{@iy}" />
     </pattern>
    """
  end

  def wall_geo(assigns) do
    ~H"""
    <polygon points="#{@points}" fill="url(#texture-#{@texture})" stroke="none"/>
    """
  end

  def portal(assigns) do
    ~H"""
    """
  end

  def entity(assigns) do
    ~H"""
    <image xlink:href="#{@img}"
           width={"#{@bx}"}
           height={"#{@by}"}
           x={"#{-0.5 * @bx}"}
           y={"#{-0.5 * @by}"}
           transform={"translate(#{@x}, #{@y}) rotate(#{rad2deg(@theta)})"} />
    """
  end
end
