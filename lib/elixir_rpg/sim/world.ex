defmodule ElixirRpg.World do
  @moduledoc """
  The World process.

  Started at application start, this has the lifecycle of:

  1. Boot process.
  2. Load cells
  """
  require ElixirRpg.RenderPool
  alias ElixirRpg.Accounts.User
  alias ElixirRpg.Entity
  require ElixirRpg.Entity

  use GenServer
  require Record
  require Logger
  alias ElixirRpg.EntitiesPool
  alias ElixirRpg.RenderPool

  alias ElixirRpg.Cell
  require ElixirRpg.Cell

  @tick_rate 1000

  Record.defrecord(:world,
    next_tick: nil,
    frame_end: nil,
    cells: nil
    # todo: user <-> entity mappings
  )

  @spec start_link([{atom(), any()}]) :: {:error, any()} | {:ok, pid}
  def start_link(__opts \\ []),
    do:
      GenServer.start_link(
        __MODULE__,
        nil,
        name: __MODULE__
      )

  @impl true
  def init(nil) do
    EntitiesPool.init()
    RenderPool.init()
    Logger.info("World starting")

    # load up our cells
    # normally, this would be from a file or something, but we're keeping it simple here
    Logger.info("Loading cells")
    cell_table = :ets.new(:world_cells, [:protected])

    [
      %{
        name: "overworld",
        bounds: [-100, -100, 1100, 1100],
        walls: [
          # W wall
          {{0, 0}, {0, 1000}, 5, "/textures/pallisade_wall.png", 128, 128},
          # N wall
          {{0, 0}, {1000, 0}, 5, "/textures/pallisade_wall.png", 128, 128},
          # E wall
          {{1000, 0}, {1000, 1000}, 5, "/textures/pallisade_wall.png", 128, 128},
          # S wall
          {{0, 1000}, {1000, 1000}, 5, "/textures/pallisade_wall.png", 128, 128}
        ],
        entities: [],
        flats: [
          # main plane
          {[{0, 0}, {0, 1000}, {1000, 1000}, {1000, 0}], "/textures/grass.png", 128, 128},
          # N/S throughfare
          {[{500, 0}, {500, 1000}, {550, 1000}, {550, 0}], "/textures/sand.png", 128, 128}
        ],
        portals: []
      },
      %{
        name: "house A",
        bounds: [-10, -10, 510, 510],
        walls: [
          # W wall
          {{0, 0}, {0, 500}, 5, "/textures/house1/wall.png", 128, 128},
          # N wall
          {{0, 0}, {500, 0}, 5, "/textures/house1/wall.png", 128, 128},
          # E wall
          {{500, 0}, {500, 500}, 5, "/textures/house1/wall.png", 128, 128},
          # S wall
          {{0, 500}, {500, 500}, 5, "/textures/house1/wall.png", 128, 128}
        ],
        entities: [],
        flats: [
          # floor
          {[{0, 0}, {0, 1000}, {1000, 1000}, {1000, 0}], "/textures/house1/wood_floor.png", 128,
           128}
        ],
        portals: []
      },
      %{
        name: "house B",
        bounds: [-10, -10, 510, 510],
        walls: [
          # W wall
          {{0, 0}, {0, 500}, 5, "/textures/house2/wall.png", 128, 128},
          # N wall
          {{0, 0}, {500, 0}, 5, "/textures/house2/wall.png", 128, 128},
          # E wall
          {{500, 0}, {500, 500}, 5, "/textures/house2/wall.png", 128, 128},
          # S wall
          {{0, 500}, {500, 500}, 5, "/textures/house2/wall.png", 128, 128}
        ],
        entities: [],
        flats: [
          # floor
          {[{0, 0}, {0, 1000}, {1000, 1000}, {1000, 0}], "/textures/house2/wood_floor.png", 128,
           128}
        ],
        portals: []
      }
    ]
    |> Enum.map(fn %{
                     name: name,
                     bounds: bounds,
                     walls: walls,
                     entities: _ents,
                     flats: flats,
                     portals: _portals
                   } ->
      Cell.cell(id: cell_id) = cell = Cell.new(name, bounds)

      Enum.map(walls, fn {wall_start, wall_end, thickness, texture, ix, iy} ->
        Cell.add_wall(cell, wall_start, wall_end, thickness, texture, ix, iy)
      end)

      Enum.map(flats, fn {verts, texture, ix, iy} ->
        Cell.add_flat(cell, verts, texture, ix, iy)
      end)

      # Enum.map(ents, fn ent -> Cell.add_entity(cell) end)

      # Enum.map(portals, fn portal -> Cell.add_portal(cell) end)

      :ets.insert(RenderPool.get_table(), {cell_id, nil, nil, nil, nil})

      :ets.insert(cell_table, {cell_id, cell})

      Logger.debug("Loaded cell #{cell_id}")
    end)

    # schedule our first update!
    Process.send_after(self(), {:tick_world}, @tick_rate)

    {:ok,
     world(
       cells: cell_table,
       frame_end: System.monotonic_time(:millisecond)
     )}
  end

  @impl true
  def handle_info({:tick_world}, world(frame_end: last_time, cells: cells_table) = w) do
    # grab timing
    now = System.monotonic_time(:millisecond)
    dt = now - last_time

    # update cells
    :ets.foldl(
      fn {_cid, cell}, _acc ->
        # update
        {cell2, _outbound_messages} = Cell.update(cell, dt)
        :ets.update_element(cells_table, 2, cell2)

        # "render" if anything interesting changed
        Cell.cell(
          walls_need_drawing: wnd,
          flats_need_drawing: fnd,
          portals_need_drawing: pnd,
          entities_need_drawing: entend,
          id: cell2_id
        ) = cell2

        if wnd or fnd or pnd or entend do
          Cell.render(cell2)
          IO.inspect(Cell.cell_topic(cell2))

          Phoenix.PubSub.broadcast(
            ElixirRpg.PubSub,
            Cell.cell_topic(cell2),
            {:cell_render_available, cell2_id}
          )
        end

        :ok
      end,
      :ok,
      cells_table
    )

    {:noreply,
     world(w,
       frame_end: now,
       next_tick: Process.send_after(self(), {:tick_world}, @tick_rate)
     )}
  end

  def get_entity_for_account(%User{id: user_id}) do
  end

  def get_cell_for_entity(Entity.entity(id: entity_id)) do
  end
end
