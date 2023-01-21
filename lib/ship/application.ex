defmodule Ship.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      Ship.Repo,
      # Start the Telemetry supervisor
      ShipWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Ship.PubSub},
      Ship.Manager,
      # Start the Endpoint (http/https)
      ShipWeb.Endpoint
      # Start a worker by calling: Ship.Worker.start_link(arg)
      # {Ship.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Ship.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ShipWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
