defmodule Twitter5.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      # Start the Ecto repository
      Twitter5.Repo,
      # Start the endpoint when the application starts
      Twitter5Web.Endpoint
      # Starts a worker by calling: Twitter5.Worker.start_link(arg)
      # {Twitter5.Worker, arg},
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Twitter5.Supervisor]
    pid = Supervisor.start_link(children, opts)
    #Create Network
    Twitter.start()
    Twitter.simulate(100,2)
    pid
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    Twitter5Web.Endpoint.config_change(changed, removed)
    :ok
  end
end
