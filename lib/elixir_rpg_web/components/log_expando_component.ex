defmodule ElixirRpgWeb.LogOverlayComponent do
  use ElixirRpgWeb, :live_component
  def render(assigns) do
    ~H"""
    <div class="fixed inset-0 flex items-center justify-center pointer-events-none">
      <div class="bg-black bg-opacity-50 p-4 rounded-lg w-2/3 h-1/2 overflow-y-auto">
        <ul id="log-messages" phx-update="stream" class="text-white">
          <li :for={{dom_id, message} <- @streams.log_messages} id={dom_id}>
            <%= message.message %>
          </li>
        </ul>
      </div>
    </div>
  """
  end
end
