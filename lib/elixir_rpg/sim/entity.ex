defmodule ElixirRpg.Entity do
  require Record
  # alias Graphmath.Vec2, as: V

  alias Ecto.UUID

  Record.defrecord(:entity,
    current_cell: nil,
    is_active: false,
    behavior: nil,
    behavior_state: nil,
    id: nil
  )

  @table_name :entity_table

  @impl true
  def new() do
    entity(id: UUID.generate())
  end

  def tick_entity(entity, frame_msecs) do
    GenServer.cast(entity, {:tick, frame_msecs})
  end

  def dump_state(entity) do
    GenServer.call(entity, :dump_state)
  end
end
