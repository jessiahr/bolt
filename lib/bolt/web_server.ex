defmodule Bolt.WebServer do
  @moduledoc """
  Serves an api for getting the status
  """
  use Plug.Router

  # plug Bolt.UiPlug
  plug Plug.Logger
  plug :match
  plug :dispatch

  forward "/bolt", to: Bolt.Router

  def child_spec(port) do
    Plug.Adapters.Cowboy.child_spec(:http, __MODULE__, [], [port: port])
  end
end
