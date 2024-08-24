defmodule ElixirRpg.Cell do
  require Logger
  require Record

  use GenServer, restart: :transient
  alias ElixirRpg.World
  alias ElixirRpg.Entity
  require ElixirRpg.Entity

  Record.defrecord(:cell,
    id: nil,
    # walls, which prevent movement
    walls_table: nil,
    # flats, which are textured polygons on the ground
    flats_table: nil,
    # portals, which are textured walls that can be interact with to move an entity
    portals_table: nil,
    # entities, which are thinky and update
    entity_table: nil
  )

  def entities_topic(id), do: "cell:#{id}:entities"
  def chat_topic(id), do: "cell:#{id}:chat"
  def user_topic(id), do: "cell:#{id}:user"
  def cell_topic(id), do: "cell:#{id}:cell"

  def new() do
    id = Ecto.UUID.generate()

    cell(
      id: String.to_atom("cell_#{id}"),
      entity_table:
        :ets.new(String.to_atom("cell_#{id}_ents"), [:protected, {:read_concurrency, true}]),
      flats_table:
        :ets.new(String.to_atom("cell_#{id}_flats"), [:protected, {:read_concurrency, true}]),
      walls_table:
        :ets.new(String.to_atom("cell_#{id}_walls"), [:protected, {:read_concurrency, true}]),
      portals_table:
        :ets.new(String.to_atom("cell_#{id}_portals"), [:protected, {:read_concurrency, true}])
    )
  end

  def update(cell(id: id) = cell, dt) do
    Logger.debug("Start update cell #{id}")

    # todo: update entities

    # todo: resolve intents

    Logger.debug("End update cell #{id}")
    :ok
  end
end
