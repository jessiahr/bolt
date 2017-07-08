defmodule Bolt.Application do
  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  require Logger

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    # Define workers and child supervisors to be supervised
    children = [
      worker(Bolt.Queue, []),
      worker(Bolt.JobStore, [])
    ]
    children = if Application.get_env(:bolt, :port) != nil do
      Logger.warn "Starting Bolt.WebServer on #{Application.get_env(:bolt, :port)}"
      [Bolt.WebServer.child_spec(Application.get_env(:bolt, :port)) | children]
    else
      children
    end
    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Bolt.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
