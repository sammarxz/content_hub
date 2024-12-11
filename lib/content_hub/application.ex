defmodule ContentHub.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ContentHubWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:content_hub, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: ContentHub.PubSub},
      # Start a worker by calling: ContentHub.Worker.start_link(arg)
      # {ContentHub.Worker, arg},
      # Start to serve requests, typically the last entry
      ContentHubWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ContentHub.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ContentHubWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
