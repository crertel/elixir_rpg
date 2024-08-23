defmodule ElixirRpgWeb.WorldLive.Index do
  use ElixirRpgWeb, :live_view


  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(ElixirRpg.PubSub, "util:log:messages")
    end

    {:ok,
     socket
     |> assign(:mouse_position, [0, 0, 0, 0])
     |> assign(:mouse_state, :up)
     |> assign(:entities, [])
     |> assign(:vb_x_min, 0)
     |> assign(:vb_y_min, 0)
     |> assign(:vb_width, 960)
     |> assign(:vb_height, 500)
     |> assign(:zoom_level, 1.0)
     |> stream( :log_messages, [])
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
    <h1> Map </h1>
    <ul>
      <li> viewBox="<%= @vb_x_min %> <%= @vb_y_min %> <%= @vb_width%> <%= @vb_height%>" </li>
      <li> mouse="<%= inspect @mouse_position %>" </li>
      <li> zoomlevel="<%= inspect @zoom_level %>"</li>
    </ul>

    <.live_component
    module={ElixirRpgWeb.LogOverlayComponent}
    id="log-overlay"
    streams={@streams}
    />

    <div phx-hook="MouseHandler"
         id="svg_canvas"
         style="width:960px; height:500px; padding: 0px; margin: 0px;">
      <svg x="0"
           y="0"
           width="960px"
           height="500px"
           viewBox={"#{@vb_x_min} #{@vb_y_min} #{@vb_width} #{@vb_height}"}
           style="border: 1px solid black; pointer-events: none; margin: 0px;">
        <defs>
          <%= for obj <- @entities do %>
            <%= raw(obj.svg_markup) %>
          <% end %>
          <pattern id="smallGrid" width="8" height="8" patternUnits="userSpaceOnUse" preserveAspectRatio="xMidYMid slice">
            <path d="M 8 0 L 0 0 0 8" fill="none" stroke="gray" stroke-width="0.5"/>
          </pattern>
          <pattern id="grid" width="80" height="80" patternUnits="userSpaceOnUse" preserveAspectRatio="xMidYMid slice">
            <rect width="80" height="80" fill="url(#smallGrid)"/>
            <path d="M 80 0 L 0 0 0 80" fill="none" stroke="gray" stroke-width="1"/>
          </pattern>
        </defs>

        <use xlink:href="#a" transform="rotate(0 150 150) translate(150 150)"/>
        <use xlink:href="#a" transform="rotate(0 150 150) translate(150 150)"/>
        <rect x="-1000" y = "-1000" width="2000px" height="2000px" preserveAspectRatio="xMidYMid slice" fill="url(#grid)" />
      </svg>
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
          socket
          |> assign(:mouse_state, :up)

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
    default_vb_bounds = Graphmath.Vec2.create(960.0, 500.0)
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

  #@max_log_buffer_size 64
  @impl true
  def handle_info({:log, message, timestamp}, socket) do
    {:noreply, stream_insert(socket, :log_messages, %{id: System.unique_integer(), message: message}, limit: -32)}
  end
end
