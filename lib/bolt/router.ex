defmodule Bolt.Router do
  @moduledoc """
  Serves an api for getting the status
  """
  use Plug.Router
  plug Plug.Parsers, parsers: [:json],
                   pass:  ["text/*"],
                   json_decoder: Poison

  plug Plug.Static,
    at: "/",
    from: Path.join([Application.app_dir(:bolt), "priv/static/"])

  plug :match
  plug :dispatch


  get "/favicon.ico" do
    conn
    |> send_resp(404, "")
    |> halt
  end

  get "/css/app.css" do
    index_path = Path.join([Application.app_dir(:bolt), "priv/static/css/app.css"])
    conn
     |> send_file(200, index_path)
     |> halt
  end

  get "/js/app.js" do
    index_path = Path.join([Application.app_dir(:bolt), "priv/static/js/app.js"])
    conn
     |> send_file(200, index_path)
     |> halt
  end

  get "/api/status" do
    params = conn
    |> fetch_query_params

    conn
    |> send_resp(200, Bolt.Queue.status |> Poison.encode!)
  end

  post "/api/:queue_name/workers" do
    case conn.body_params do
      %{"worker_max" => worker_max} ->
        :ok = Bolt.Queue.set_worker_max(queue_name, worker_max)
        conn
        |> send_resp(200, "success")
      other ->
        conn
        |> send_resp(302, "meh?")
    end
  end

  match _ do
    index_path = Path.join([Application.app_dir(:bolt), "priv/static/index.html"])
    conn
     |> send_file(200, index_path)
     |> halt
  end
end
