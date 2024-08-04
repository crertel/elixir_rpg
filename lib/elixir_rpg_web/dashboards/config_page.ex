defmodule ElixirRpgWeb.ConfigPage do
  @moduledoc false
  use Phoenix.LiveDashboard.PageBuilder

  alias ElixirRpgWeb.CoreComponents

  @impl true
  def menu_link(_, _) do
    {:ok, "App Config"}
  end

  @impl true
  def mount(params, sessions, socket) do
    applications = :application.which_applications() |> Enum.map(&(&1 |> elem(0)))

    config_vars =
      Enum.reduce(applications, [], fn app, vars ->
        vars ++
          (:application.get_all_env(app)
           |> Enum.map(fn {namespace, value} ->
             %{
               id: System.unique_integer([:positive]),
               appname: app,
               module: namespace,
               key: "",
               value: inspect(value, pretty: true)
             }
           end))
      end)

    Process.put(:the_known_config, config_vars)
    {:ok, socket |> assign(current_values: 0)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <CoreComponents.modal show={@current_values} id="details">
        <%= inspect(@current_values, pretty: true) %>
      </CoreComponents.modal>
      <.live_table
        id="config-table"
        dom_id="config-table"
        page={@page}
        title="Configs"
        row_fetcher={&fetch_config/2}
        row_attrs={&row_attrs/1}
        rows_name="variables"
      >
        <:col field={:appname} header="Application" sortable={:desc} />
        <:col field={:module} header="Module" sortable={:desc} />
        <:col field={:key} header="Key" sortable={:desc} />
        <:col field={:value} header="Value" sortable={:desc} />
      </.live_table>
    </div>
    """
  end

  #  <.CoreComponents.modal :if={false} id="details">
  #      <%= inspect(@current_values, pretty: true) %>
  #    </.CoreComponents.modal>

  defp fetch_config(params, node) do
    %{search: search, sort_by: sort_by, sort_dir: sort_dir, limit: limit} = params

    config_vars = Process.get(:the_known_config)
    {config_vars, length(config_vars)}
  end

  defp row_attrs(table) do
    [
      {"phx-click", CoreComponents.show_modal("details")},
      {"phx-value-info", table[:id]}
      # {"phx-page-loading", true}
    ]
  end

  def handle_event("show_info", %{"info" => id}, socket) do
    cfg = Process.get(:the_known_config)
    {:noreply, socket |> assign(current_values: id)}
  end
end
