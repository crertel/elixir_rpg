defmodule ElixirRpgWeb.WorldLive.Index do
  use ElixirRpgWeb, :live_view
  alias ElixirRpg.RenderPool

  alias ElixirRpg.World

  # remember, 128px = 1 unit = 1 meter

  @canvas_width 1280
  @canvas_height 720

  @impl true
  def mount(_params, _session, socket) do
    cell_id = World.get_cell_id_for_name("overworld")

    socket =
      socket
      |> refresh_cell(cell_id)
      |> reset_mouse()
      |> reset_viewport()
      # |> lookat_viewport({0, 0}, 1)
      |> assign(:entities, [])
      |> assign(:cell_id, cell_id)
      |> assign(:show_logs, false)
      |> assign(:canvas_width, @canvas_width)
      |> assign(:canvas_height, @canvas_height)
      |> stream(:chat_messages, [])
      |> stream(:log_messages, [])

    if connected?(socket) do
      # subscribe to logging
      Phoenix.PubSub.subscribe(ElixirRpg.PubSub, "util:log:messages")

      # figure out what cell we're supposed to be in
      Phoenix.PubSub.subscribe(ElixirRpg.PubSub, "user:#{socket.assigns.current_user.id}:*")

      Phoenix.PubSub.subscribe(ElixirRpg.PubSub, "cell")

      # user_entity = World.get_entity_for_account(socket.assigns.current_user)
      # user_cell = World.get_cell_for_user(socket)

      {:ok, socket}
    else
      {:ok, socket}
    end
  end

  defp reset_mouse(socket),
    do:
      assign(socket, %{
        mouse_position: [0, 0, 0, 0],
        mouse_state: :up
      })

  defp reset_viewport(socket),
    do:
      assign(socket, %{
        vb_x_min: 0,
        vb_y_min: 0,
        vb_width: @canvas_width,
        vb_height: @canvas_height,
        zoom_level: 1.0
      })

  defp lookat_viewport(socket, {target_x, target_y}, zoom_level) do
    aspect_ratio =
      assign(socket, %{
        vb_x_min: target_x - 0.5 * @canvas_width * zoom_level,
        vb_y_min: target_y - 0.5 * @canvas_height * zoom_level,
        vb_width: @canvas_width * zoom_level,
        vb_height: @canvas_height * zoom_level,
        zoom_level: zoom_level
      })
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col items-center">
      <h1 class="text-3xl text-zinc-300">Map</h1>
      <ul class="bg-zinc-300 w-1/2">
        <li>viewBox="<%= @vb_x_min %> <%= @vb_y_min %> <%= @vb_width %> <%= @vb_height %>"</li>
        <li>mouse="<%= inspect(@mouse_position) %>"</li>
        <li>zoomlevel="<%= inspect(@zoom_level) %>"</li>
        <li>cellid="<%= @cell_id%>"</li>
      </ul>

      <.live_component
        module={ElixirRpgWeb.LogOverlayComponent}
        id="log-overlay"
        streams={@streams}
        show={@show_logs}
      />

      <div
        phx-hook="MouseHandler"
        id="svg_canvas"
        style={"min-width: #{@canvas_width}px; min-height: #{@canvas_height}px; padding: 0px; margin: 0px;"}
      >
        <svg
          x="0"
          y="0"
          width={# {@canvas_width}px"}
          height={"#{@canvas_height}px"}
          viewBox={"#{@vb_x_min} #{@vb_y_min} #{@vb_width} #{@vb_height}"}
          style="border: 1px solid black; pointer-events: none; margin: 0px;"
        >
          <defs>
          <%= raw(@svg_flat_defs) %>
          <%= raw(@svg_wall_defs) %>
          <%= raw(@svg_ent_defs) %>
          <%= raw(@svg_portal_defs) %>
          </defs>

          <g transform="scale(1,-1)">
            <%= raw(@svg_flat_geos) %>
            <%= raw(@svg_wall_geos) %>
            <%= raw(@svg_ent_geos) %>
            <%= raw(@svg_portal_geos) %>

            <line x1="0" y1="0" x2="10" y2="0" stroke-width="1" stroke="#0F0" />
            <line x1="0" y1="0" x2="0" y2="10" stroke-width="1" stroke="#F00" />
          </g>
        </svg>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("mouse_enter", _, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "mouse_leave",
        %{"p" => [x, y], "np" => [nx, ny]},
        %{
          assigns: %{
            mouse_state: mouse_state
          }
        } = socket
      ) do
    s =
      case mouse_state do
        :drag ->
          assign(socket, :mouse_state, :up)

        :down ->
          assign(socket, :mouse_state, :up)

        :up ->
          socket
      end
      |> assign(:mouse_position, [x, y, nx, ny])

    {:noreply, s}
  end

  @impl true
  def handle_event(
        event,
        %{
          "p" => [x, y],
          "np" => [nx, ny],
          "b" => _mouse_button
        },
        %{
          assigns: %{}
        } = socket
      )
      when event in ~W"mouse_up mouse_down" do
    s =
      case event do
        "mouse_up" ->
          socket
          |> assign(:mouse_state, :up)

        "mouse_down" ->
          assign(socket, :mouse_state, :down)
      end
      |> assign(:mouse_position, [x, y, nx, ny])

    {:noreply, s}
  end

  @impl true
  def handle_event(
        "mouse_wheel",
        %{"d" => [_dx, dy, _dz]},
        %{
          assigns: %{
            zoom_level: old_zoom_level,
            vb_x_min: old_vb_x_min,
            vb_y_min: old_vb_y_min,
            vb_width: old_vb_width,
            vb_height: old_vb_height,
            mouse_position: [_x, _y, nx, ny]
          }
        } = socket
      ) do
    # calculate our zoom scale based on our zoom level
    old_zoom_scale = :math.exp(old_zoom_level / 10)
    clamped = max(-1, min(1, dy))
    new_zoom_level = old_zoom_level + clamped
    new_zoom_scale = :math.exp(new_zoom_level / 10)

    # calculate the old and new bounds
    old_vb_bounds = Graphmath.Vec2.create(old_vb_width, old_vb_height)
    default_vb_bounds = Graphmath.Vec2.create(@canvas_width, @canvas_height)
    new_vb_bounds = Graphmath.Vec2.scale(default_vb_bounds, new_zoom_scale)

    # finally, calculate the origin/minimum point of the view box
    # for the rough algo, check this explanation:
    # https://medium.com/@benjamin.botto/zooming-at-the-mouse-coordinates-with-affine-transformations-86e7312fd50b
    old_vb_min = Graphmath.Vec2.create(old_vb_x_min, old_vb_y_min)

    # create zoom point from where the mouse is, in world coords
    zoom_point_world =
      Graphmath.Vec2.create(nx, ny)
      |> Graphmath.Vec2.multiply(old_vb_bounds)
      |> Graphmath.Vec2.add(old_vb_min)

    new_vb_min =
      old_vb_min
      |> Graphmath.Vec2.subtract(zoom_point_world)
      |> Graphmath.Vec2.scale(new_zoom_scale / old_zoom_scale)
      |> Graphmath.Vec2.add(zoom_point_world)

    {new_vb_x_min, new_vb_y_min} = new_vb_min
    {new_vb_width, new_vb_height} = new_vb_bounds

    s =
      socket
      |> assign(:zoom_level, new_zoom_level)
      |> assign(:vb_x_min, new_vb_x_min)
      |> assign(:vb_y_min, new_vb_y_min)
      |> assign(:vb_width, max(new_vb_width, 0.0))
      |> assign(:vb_height, max(new_vb_height, 0.0))

    {:noreply, s}
  end

  @impl true
  def handle_event(
        "mouse_move",
        %{
          "p" => [x, y],
          "np" => [nx, ny]
        },
        %{
          assigns: %{
            mouse_state: mouse_state,
            vb_x_min: vb_x_min,
            vb_y_min: vb_y_min,
            vb_width: vb_width,
            vb_height: vb_height,
            mouse_position: [_oldx, _oldy, oldnx, oldny]
          }
        } = socket
      ) do
    s =
      case mouse_state do
        :up ->
          socket

        :down ->
          socket
          |> assign(:mouse_state, :drag)

        :drag ->
          socket
          |> assign(:vb_x_min, vb_x_min - vb_width * (nx - oldnx))
          |> assign(:vb_y_min, vb_y_min - vb_height * (ny - oldny))
      end
      |> assign(:mouse_position, [x, y, nx, ny])

    {:noreply, s}
  end

  def handle_event(name, params, %{assigns: assigns} = socket) do
    IO.inspect(%{params: params, assigns: assigns}, label: "Unhandled Event #{name}")

    {:noreply, socket}
  end

  @impl true
  @spec handle_info({Logger, any(), any()}, Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_info({Logger, level, message}, socket) do
    {:noreply,
     stream_insert(
       socket,
       :log_messages,
       %{
         id: System.unique_integer(),
         level: level,
         message: "#{message}"
       },
       limit: -32
     )}
  end

  def handle_info({:cell_render_available, cell_id}, socket) do
    {:noreply, refresh_cell(socket, cell_id)}
  end

  def refresh_cell(socket, cell_id) do
    case :ets.lookup(RenderPool.get_table(), cell_id) do
      [
        {_cid, {wall_defs, wall_geos}, {flat_defs, flat_geos}, {ent_defs, ent_geos},
         {portal_defs, portal_geos}}
      ] ->
        assign(socket,
          svg_flat_defs: flat_defs |> IO.inspect(label: "flat"),
          svg_wall_defs: wall_defs,
          svg_ent_defs: ent_defs,
          svg_portal_defs: portal_defs,
          svg_flat_geos: flat_geos,
          svg_wall_geos: wall_geos,
          svg_ent_geos: ent_geos |> IO.inspect(label: "ents"),
          svg_portal_geos: portal_geos
        )

      _ ->
        assign(socket, svg_defs: "", svg_geos: "")
    end
  end
end
