defmodule Bolt.WebServer do
  @moduledoc """
  Serves an api for getting the status
  """
  use Plug.Router

  plug Plug.Logger
  plug :match
  plug :dispatch

  get "/favicon.ico" do
    conn
    |> send_resp(404, "")
    |> halt
  end

  get "/" do
    params = conn
    |> fetch_query_params

    conn
    |> send_resp(200, Bolt.Queue.status |> Poison.encode!)
  end

  def child_spec(port) do
    Plug.Adapters.Cowboy.child_spec(:http, __MODULE__, [], [port: port])
  end
end
