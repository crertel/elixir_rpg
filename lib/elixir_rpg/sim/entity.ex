defmodule ElixirRpg.Entity do
  require Record

  # alias Graphmath.Vec2, as: V

  alias Ecto.UUID

  Record.defrecord(:entity,
    behavior: nil,
    behavior_state: nil,
    name: nil,
    id: nil
  )

  @table_name :entity_table

  @impl true
  def new() do
    entity(id: UUID.generate())
  end

  def dump_state(entity) do
    inspect(entity)
  end
end
