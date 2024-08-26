defmodule ElixirRpg.Cell do
  require ElixirRpg.RenderPool
  alias ElixirRpg.Render.PortalRenderer
  alias ElixirRpg.Render.EntityRenderer
  alias ElixirRpg.Render.FlatRenderer
  alias ElixirRpg.RenderPool
  require Logger
  require Record

  alias Graphmath.Vec2, as: V
  alias ElixirRpg.Render.WallRenderer

  require ElixirRpg.Entity

  Record.defrecord(:cell,
    id: nil,
    name: nil,
    bounds: nil,
    # walls, which prevent movement
    walls_table: nil,
    walls_need_drawing: true,
    # flats, which are textured polygons on the ground
    flats_table: nil,
    flats_need_drawing: true,
    # portals, which are textured walls that can be interact with to move an entity
    portals_table: nil,
    portals_need_drawing: true,
    # entities, which are thinky and update
    entity_table: nil,
    entities_need_drawing: true
  )

  # ef entities_topic(id), do: "cell:#{id}:entities"
  # def chat_topic(id), do: "cell:#{id}:chat"
  # def user_topic(id), do: "cell:#{id}:user"
  # def cell_topic(cell(id: cell_id)), do: "cell:#{cell_id}"
  def cell_topic(_), do: "cell"

  @spec new(any(), any()) ::
          {:cell, atom(), any(), any(), atom() | :ets.tid(), true, atom() | :ets.tid(), true,
           atom() | :ets.tid(), true, atom() | :ets.tid(), true}
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

  def update(cell(id: id, entity_table: entity_table) = cell, _dt) do
    Logger.debug("Start update cell #{id}")

    # todo: update entities
    :ets.foldl(
      fn {_eid, _entity}, acc ->
        # Cell.update(cell, dt)
        acc
      end,
      [],
      entity_table
    )

    # todo: resolve intents
    Logger.debug("End update cell #{id}")
    {cell, []}
  end

  def render(
        cell(
          id: cell_id,
          entity_table: ents,
          entities_need_drawing: entnd,
          walls_table: walls,
          walls_need_drawing: wnd,
          flats_table: flats,
          flats_need_drawing: fnd,
          portals_table: portals,
          portals_need_drawing: pnd
        ) = cell
      ) do
    [
      {walls, wnd, RenderPool.cell_svg(:wall_svg), WallRenderer},
      {flats, fnd, RenderPool.cell_svg(:flats_svg), FlatRenderer},
      {ents, entnd, RenderPool.cell_svg(:ents_svg), EntityRenderer},
      {portals, pnd, RenderPool.cell_svg(:portals_svg), PortalRenderer}
    ]
    |> Enum.map(fn {renderable_table, should_render, renderable_offset, renderer} ->
      if should_render do
        {defs_markup, geo_markup} =
          :ets.foldl(
            fn {_, opts}, {defs, geos} ->
              {stroke_def, geo} =
                renderer.render(opts)

              {[stroke_def | defs], [geo | geos]}
            end,
            {[], []},
            renderable_table
          )

        :ets.update_element(
          RenderPool.get_table(),
          cell_id,
          {renderable_offset,
           {
             defs_markup,
             geo_markup
           }}
        )
      end
    end)
  end

  def render(_) do
    # Logger.warning("Unkonwn cell render on #{inspect(c)}")
  end

  def add_wall(cell(walls_table: walls) = _cell, wall_start, wall_end, thickness, texture, ix, iy) do
    :ets.insert(walls, {make_ref(), {wall_start, wall_end, thickness, texture, ix, iy}})
  end

  def add_flat(cell(flats_table: flats) = _cell, verts, texture, ix, iy) do
    :ets.insert(flats, {make_ref(), {verts, texture, ix, iy}})
  end

  def add_entity(cell() = _cell) do
  end

  def add_portal(cell() = _cell) do
  end
end
