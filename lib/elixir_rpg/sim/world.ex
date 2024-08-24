defmodule ElixirRpg.World do
  @moduledoc """
  The World process.

  Started at application start, this has the lifecycle of:

  1. Boot process.
  2. Load cells
  """
  alias ElixirRpg.Accounts.User
  alias ElixirRpg.Entity
  require ElixirRpg.Entity
  # alias ElixirRpg.Cell

  use GenServer
  require Record
  require Logger
  alias ElixirRpg.EntitiesPool

  alias ElixirRpg.Cell
  require ElixirRpg.Cell

  @tick_rate 100

  Record.defrecord(:world,
    next_tick: nil,
    frame_end: nil,
    cells: nil
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
    Logger.info("World starting")

    # load up our cells
    # normally, this would be from a file or something, but we're keeping it simple here
    Logger.info("Loading cells")
    cell_table = :ets.new(:world_cells, [:protected])

    [
      {
        # overworld cell
      },
      {
        # house A
      },
      {
        # house B
      }
    ]
    |> Enum.map(fn {} ->
      cell = Cell.new()
      cell_id = Cell.cell(cell, :id)
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
      fn {cid, cell}, acc ->
        Cell.update(cell, dt)
        acc
      end,
      [],
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
