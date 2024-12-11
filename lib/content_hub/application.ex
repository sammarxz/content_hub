defmodule ContentHub.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ContentHubWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:content_hub, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: ContentHub.PubSub},
      # Start Finch before MetaFetcher since MetaFetcher depends on it
      {Finch, name: ContentHub.Finch},
      # Start MetaFetcher with explicit name
      {ContentHub.MetaFetcher, name: ContentHub.MetaFetcher},
      ContentHubWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: ContentHub.Supervisor]

    case Supervisor.start_link(children, opts) do
      {:ok, pid} ->
        {:ok, pid}

      {:error, reason} ->
        require Logger
        Logger.error("Failed to start application supervisor: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @impl true
  def config_change(changed, _new, removed) do
    ContentHubWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
