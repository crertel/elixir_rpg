defmodule ElixirRpg.RenderPool do
  @moduledoc """
  Wrapper around an ETS table to handle caching rendered cells.

  """
  require Record
  require ElixirRpg.Entity

  Record.defrecord(:cell_svg,
    id: nil,
    wall_svg: nil,
    flats_svg: nil,
    ents_svg: nil,
    portals_svg: nil
  )

  def init() do
    :ets.new(__MODULE__, [:named_table, :public, :set, {:read_concurrency, true}])
  end

  def get_table(), do: __MODULE__
end
