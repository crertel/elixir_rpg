defmodule ElixirRpg.Util.Math do
  @compile {:deg2rad, myfun: 1}
  def deg2rad(degrees), do: degrees * :math.pi() / 180.0

  @compile {:rad2deg, myfun: 1}
  def rad2deg(radians), do: radians * 180.0 / :math.pi()
end
