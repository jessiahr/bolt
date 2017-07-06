defmodule Bolt.JobStore do
  use GenServer
  require Logger
  #https://stackoverflow.com/questions/22001247/redis-how-to-store-associative-array-set-or-hash-or-list

  def start_link do
    GenServer.start_link(__MODULE__, %{}, [name: __MODULE__])
  end

  def add(queue_name, job_params) do
    GenServer.call(__MODULE__, {:add, queue_name, job_params})
  end

  def start(queue_name) do
    GenServer.call(__MODULE__, {:start, queue_name})
  end

  def finish(queue_name, job_id) do
    GenServer.call(__MODULE__, {:finish, queue_name, job_id})
  end

  def init(state) do
    case Redix.start_link(Application.get_env(:bolt, :redis_url)) do
      {:ok, conn} ->
          Logger.warn "Starting! JobStore"
        {:ok, %{conn: conn}}
      other ->
        Logger.raise other
        {:error, "Something went wrong"}
    end
  end

  def handle_call({:add, queue_name, job_params}, _from, state = %{conn: conn}) do
    job_id = UUID.uuid1()
    status = Redix.command(conn, ["HSET", "#{queue_name}:jobs:id#{job_id}", "params", Poison.encode!(job_params)])
    status = Redix.command(conn, ["LPUSH", "#{queue_name}:waiting", "#{queue_name}:jobs:id#{job_id}"])
    {:reply, {:ok, job_id}, state}
  end

  def handle_call({:start, queue_name}, _from, state = %{conn: conn}) do
    {:ok, job_id} = Redix.command(conn, ["RPOP", "#{queue_name}:waiting"])
    backup_job(conn, queue_name, job_id)
    {:ok, job} = Redix.command(conn, ["HGETALL", job_id])
    {:reply, {:ok, job_id, job}, state}
  end

  def handle_call({:finish, queue_name, job_id}, _from, state = %{conn: conn}) do
    {:ok, result} = Redix.command(conn, ["DEL", job_id])
    remove_backup_job(conn, queue_name, job_id)
    {:reply, :ok, state}
  end

  def backup_job(conn, queue_name, nil), do: nil
  def backup_job(conn, queue_name, job_id) do
    Redix.command(conn, ["LPUSH", "#{queue_name}:inprogress", job_id])
  end

  def remove_backup_job(conn, queue_name, nil), do: nil
  def remove_backup_job(conn, queue_name, job_id) do
    Redix.command(conn, ["LREM", "#{queue_name}:inprogress", 0, job_id])
  end
end
