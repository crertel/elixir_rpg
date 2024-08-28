defmodule ElixirRpg.RenderPool do
  @moduledoc """
  Wrapper around an ETS table to handle caching cell renderables.
  """

  def init() do
    :ets.new(__MODULE__, [:named_table, :public, :set, {:read_concurrency, true}])
  end

  def get_table(), do: __MODULE__

  def set_cell_renderables(cell_id, flats, walls, entities, portals), do:
    :ets.insert(__MODULE__, {cell_id, {flats, walls, entities, portals}})

  def get_cell_renderables!(cell_id) do
    [{flats, walls, entities, portals}] = :ets.lookup(__MODULE__, cell_id)
    %{
      flats: flats,
      walls: walls,
      entities: entities,
      portals: portals
    }
  end
end
