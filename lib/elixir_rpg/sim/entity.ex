defmodule ElixirRpg.Entity do
  require Record
  alias Graphmath.Vec2, as: V
  use GenServer, restart: :transient
  alias Ecto.UUID

  Record.defrecord(:entity,
    current_cell: nil,
    is_active: false,
    behavior: nil,
    behavior_state: nil,
    id: nil
  )

  @table_name :entity_table

  @spec start_link([{atom(), any()}]) :: {:error, any()} | {:ok, pid}
  def start_link(_entity) do
    entity = entity(id: UUID.generate())
    GenServer.start_link(__MODULE__, entity(), name: process_name(entity))
  end

  def process_name(entity(id: eid)) do
    {:via, Registry, {EntityRegistry, "entity_#{eid}"}}
  end

  @impl true
  def init(entity) do
    {:ok, entity, {:continue, nil}}
  end

  @impl true
  def handle_continue(nil, entity) do
    {:noreply, entity}
  end

  def tick_entity(entity, frame_msecs) do
    GenServer.cast(entity, {:tick, frame_msecs})
  end

  def dump_state(entity) do
    GenServer.call(entity, :dump_state)
  end

  def handle_call(:dump_state, state) do
    {:reply, state, state}
  end

  def handle_cast({:tick, dt_millisecs}, _from, entity(id: eid, behavior: behavior) = state) do
    IO.puts("tick #{eid}")
    old_state = :ets.lookup(@table_name, eid)
    {:ok, new_state} = apply(behavior, :tick, [old_state, dt_millisecs])

    {:noreply, entity(state, behavior_state: new_state)}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end
end
