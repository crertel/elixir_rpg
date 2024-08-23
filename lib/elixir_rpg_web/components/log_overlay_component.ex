defmodule ElixirRpgWeb.LogExpandoComponent do
  use ElixirRpgWeb, :live_component
  def render(assigns) do
    ~H"""
     <div class="fixed bottom-4 right-4">
      <details class="bg-white shadow-lg rounded-lg overflow-hidden">
        <summary class="bg-gray-800 text-white p-2 cursor-pointer">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 inline-block mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z" />
          </svg>
          Logs
        </summary>
        <div class="p-4 max-h-96 overflow-y-auto">
          <ul id="log-messages" phx-update="stream" class="text-sm">
            <li :for={{dom_id, message} <- @streams.log_messages} id={dom_id} class="mb-1 pb-1 border-b border-gray-200">
              <%= message.message %>
            </li>
          </ul>
        </div>
      </details>
    </div>
  """
  end
end
