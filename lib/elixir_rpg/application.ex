defmodule ElixirRpg.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ElixirRpgWeb.Telemetry,
      ElixirRpg.Repo,
      {DNSCluster, query: Application.get_env(:elixir_rpg, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: ElixirRpg.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: ElixirRpg.Finch},
      # Start a worker by calling: ElixirRpg.Worker.start_link(arg)
      # {ElixirRpg.Worker, arg},
      # Start to serve requests, typically the last entry
      ElixirRpgWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ElixirRpg.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ElixirRpgWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
