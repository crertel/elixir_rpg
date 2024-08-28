defmodule ElixirRpg.World do
  @moduledoc """
  The World process.

  Started at application start, this has the lifecycle of:

  1. Boot process.
  2. Load cells
  """
  use GenServer

  require ElixirRpg.Cell
  require ElixirRpg.RenderPool
  require Record
  require Logger

  alias ElixirRpg.Accounts.User
  alias ElixirRpg.Cell
  alias ElixirRpg.EntitiesPool

  alias ElixirRpg.RenderPool

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
    # EntitiesPool.init()
    RenderPool.init()
    Logger.info("World starting")

    # load up our cells
    # normally, this would be from a file or something, but we're keeping it simple here
    Logger.info("Loading cells")
    cell_table = :ets.new(:world_cells, [:protected, :named_table])

    [
      %{
        name: "overworld",
        bounds: [-10, -10, 110, 110],
        walls: [
          # W wall
          {1, {0, 0}, {0, 100}, 5, "/textures/overworld/pallisade_wall.png", 128, 128},
          # N wall
          {2, {0, 0}, {100, 0}, 5, "/textures/overworld/pallisade_wall.png", 128, 128},
          # E wall
          {3, {100, 0}, {100, 100}, 5, "/textures/overworld/pallisade_wall.png", 128, 128},
          # S wall
          {4, {0, 100}, {100, 100}, 5, "/textures/overworld/pallisade_wall.png", 128, 128}
        ],
        entities: [
          {ElixirRpg.Brains.PropBrain,
           %{pos: {10, 10}, bounds: {4, 4}, a: 0, img: "/textures/props/shrub.png"}}
        ],
        flats: [
          # main plane
          {1, [{0, 0}, {0, 100}, {100, 100}, {100, 0}], "/textures/overworld/grass.png", 512,
           512},
          # N/S throughfare
          {2, [{50, 0}, {50, 100}, {55, 100}, {55, 0}], "/textures/overworld/sand.png", 512, 512},

          # house A
          {3, [{55, 70}, {55, 75}, {70, 75}, {70, 70}], "/textures/overworld/sand.png", 512, 512},

          # house B
          {4, [{20, 20}, {20, 25}, {50, 25}, {50, 20}], "/textures/overworld/sand.png", 512, 512}
        ],
        portals: []
      },
      %{
        name: "house A",
        bounds: [0, 0, 10, 10],
        walls: [
          # W wall
          {1, {0, 0}, {0, 10}, 1, "/textures/house1/wall.png", 128, 128},
          # N wall
          {2, {0, 0}, {10, 0}, 1, "/textures/house1/wall.png", 128, 128},
          # E wall
          {3, {10, 0}, {10, 10}, 1, "/textures/house1/wall.png", 128, 128},
          # S wall
          {4, {0, 10}, {10, 10}, 1, "/textures/house1/wall.png", 128, 128}
        ],
        entities: [],
        flats: [
          # floor
          {1, [{0, 0}, {0, 10}, {10, 10}, {10, 0}], "/textures/house1/floor.png", 640, 640},
          # dirt
          {2, [{0, 0}, {0, 10}, {10, 10}, {10, 0}], "/textures/house1/floor_dirt.png", 1280, 1280}
        ],
        portals: []
      },
      %{
        name: "house B",
        bounds: [0, 0, 10, 10],
        walls: [
          # W wall
          {1, {0, 0}, {0, 10}, 1, "/textures/house2/wall.png", 128, 128},
          # N wall
          {2, {0, 0}, {10, 0}, 1, "/textures/house2/wall.png", 128, 128},
          # E wall
          {3, {10, 0}, {10, 10}, 1, "/textures/house2/wall.png", 128, 128},
          # S wall
          {4, {0, 10}, {10, 10}, 1, "/textures/house2/wall.png", 128, 128}
        ],
        entities: [],
        flats: [
          # floor
          {1, [{0, 0}, {0, 1000}, {1000, 1000}, {1000, 0}], "/textures/house2/floor.png", 128,
           128}
        ],
        portals: []
      }
    ]
    |> Enum.map(fn %{
                     name: name,
                     bounds: bounds,
                     walls: walls,
                     entities: ents,
                     flats: flats,
                     portals: portals
                   } ->
      Cell.cell(id: cell_id) = cell = Cell.new(name, bounds)

      Enum.map(walls, fn {idx, wall_start, wall_end, thickness, texture, ix, iy} ->
        Cell.add_wall(cell, idx, wall_start, wall_end, thickness, texture, ix, iy)
      end)

      Enum.map(flats, fn {idx, verts, texture, ix, iy} ->
        Cell.add_flat(cell, idx, verts, texture, ix, iy)
      end)

      Enum.map(ents, fn {brain, opts} ->
        Cell.add_entity(cell, brain, opts)
      end)

      Enum.map(portals, fn portal -> Cell.add_portal(cell, portal) end)

      # initialize the cell in the render pool
      :ets.insert(RenderPool.get_table(), {cell_id, nil, nil, nil, nil})

      # commit the cell to the cell table
      :ets.insert(cell_table, {cell_id, name, cell})

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
      fn {_cid, _cell_name, cell}, _acc ->
        # update
        {cell2, _outbound_messages} = Cell.update(cell, dt)

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

          Phoenix.PubSub.broadcast(
            ElixirRpg.PubSub,
            Cell.cell_topic(cell2),
            {:cell_render_available, cell2_id}
          )
        end

        # clear render flags
        :ets.update_element(
          cells_table,
          cell2_id,
          {3,
           Cell.cell(
             cell2,
             walls_need_drawing: false,
             flats_need_drawing: false,
             portals_need_drawing: false,
             entities_need_drawing: false
           )}
        )

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

  def get_cell_id_for_name(name) do
    [[id]] = :ets.match(:world_cells, {:"$1", name, :_})
    id
  end

  def get_cell_by_id(id) do
    case :ets.lookup(:world_cells, id) do
      [] -> {:error, :notfound}
      [{^id, _, Cell.cell() = c}] -> {:ok, c}
    end
  end

  def get_cell_by_id!(id) do
    case :ets.lookup(:world_cells, id) do
      [] -> nil
      [{^id, _, Cell.cell() = c}] -> c
    end
  end

  def get_entity_by_id(id) do
    :nyi
  end

  def spawn_entity(cell, {x, y}, opts),
    do: GenServer.cast(__MODULE__, {:spawn_entity, cell, {x, y}, opts})

  @impl true
  def handle_call(
        {:spawn_entity, cell, {x, y}, opts},
        _from,
        world(frame_end: last_time, cells: cells_table) = w
      ) do
  end
end
