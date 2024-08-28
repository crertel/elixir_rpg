defmodule ElixirRpg.Brains.PropBrain do
  import ElixirRpg.Util.Math

  def update(_cell, state, _messages, dt) do
    # we're a prop, we don't do anything, really
    {state, []}
  end

  def render(%{pos: {x, y}, bounds: {bx, by}, a: theta, img: img}) do
    {
      """
      """,
      """
      <image xlink:href="#{img}" width="#{bx}" height="#{by}" x="#{-0.5 * bx}" y="#{-0.5 * by} transform="translate(#{x}, #{y}) rotate(#{rad2deg(theta)})"
      """
    }
  end
end
