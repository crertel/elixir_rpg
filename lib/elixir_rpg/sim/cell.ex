defmodule ElixirRpg.Cell do
  require ElixirRpg.RenderPool
  alias ElixirRpg.Render.WallRenderer
  alias ElixirRpg.Render.PortalRenderer
  alias ElixirRpg.Render.EntityRenderer
  alias ElixirRpg.Render.FlatRenderer
  alias ElixirRpg.RenderPool
  require Logger

  require Record

  alias Graphmath.Vec2, as: V

  Record.defrecord(:cell,
    id: nil,
    name: nil,
    bounds: nil,
    # walls, which prevent movement
    walls_table: nil,
    # flats, which are textured polygons on the ground
    flats_table: nil,
    # portals, which are textured walls that can be interact with to move an entity
    portals_table: nil,
    # entities, which are thinky and update
    entity_table: nil
  )

  def cell_topic(cell_id), do: "cell-#{cell_id}"

  def new(name, bounds) do
    id = Ecto.UUID.generate()

    cell(
      id: String.to_atom("cell_#{id}"),
      name: name,
      bounds: bounds,
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

  def update(cell(id: id, entity_table: entity_table) = cell, dt) do
    Logger.debug("Start update cell #{id}")

    # todo: update entities
    :ets.foldl(
      fn {eid, {brain, state}}, acc ->
        # TODO message
        {new_state, _out_mesages} = brain.update(cell, state, [], dt)

        :ets.insert(entity_table, {eid, {brain, new_state}})

        # do nothin atm
        acc
      end,
      [],
      entity_table
    )

    outbound_messages = []

    Logger.debug("End update cell #{id}")
    {cell, outbound_messages}
  end

  def render(
        cell(
          id: cell_id,
          entity_table: ents,
          walls_table: walls,
          flats_table: flats,
          portals_table: portals
        ) = _cell
      ) do

    rendered_walls = :ets.foldl(fn {_, opts }, acc ->
      [ WallRenderer.render(opts) | acc]
    end,[], walls)

    rendered_flats = :ets.foldl(fn {_, opts}, acc ->
      [FlatRenderer.render(opts) | acc]
    end, [], flats)

    rendered_entities = :ets.foldl(fn {_, opts}, acc ->
      [EntityRenderer.render(opts) | acc]
    end, [], ents)

    rendered_portals = :ets.foldl(fn {_, opts}, acc ->
      [PortalRenderer.render(opts) | acc]
    end, [], portals)

    RenderPool.set_cell_renderables(
      cell_id,
      rendered_flats,
      rendered_walls,
      rendered_entities,
      rendered_portals)
  end

  def add_wall(
        cell(walls_table: walls) = _cell,
        idx,
        wall_start,
        wall_end,
        thickness,
        texture,
        ix,
        iy
      ) do
    :ets.insert(walls, {make_ref(), {idx, wall_start, wall_end, thickness, texture, ix, iy}})
  end

  def add_flat(cell(flats_table: flats) = _cell, idx, verts, texture, ix, iy) do
    :ets.insert(flats, {make_ref(), {idx, verts, texture, ix, iy}})
  end

  def add_entity(cell(entity_table: ents) = _cell, brain, initial_state) do
    :ets.insert(ents, {make_ref(), {brain, initial_state}})
  end

  def add_portal(cell() = _cell, _portal) do
    :nyi
  end
end
