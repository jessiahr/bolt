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

  def remaining_count(queue_name) do
    GenServer.call(__MODULE__, {:remaining_count, queue_name})
  end

  def resume_inprogress(queue_name) do
    GenServer.call(__MODULE__, {:resume_inprogress, queue_name})
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
    Redix.pipeline!(
      conn,
      [
        ["HSET", "#{queue_name}:jobs:id#{job_id}", "params", Poison.encode!(job_params)],
        ["LPUSH", "#{queue_name}:waiting", "#{queue_name}:jobs:id#{job_id}"]
      ]
    )
    {:reply, {:ok, job_id}, state}
  end

  def handle_call({:start, queue_name}, _from, state = %{conn: conn}) do
    {:ok, job_id} = Redix.command(conn, ["RPOP", "#{queue_name}:waiting"])
    backup_job(conn, queue_name, job_id)
    {:ok, job} = Redix.command(conn, ["HGET", job_id, "params"])
    {:reply, {:ok, job_id, decode_job(job)}, state}
  end

  defp decode_job(nil), do: nil
  defp decode_job(job) do
    Poison.decode!(job)
  end

  def handle_call({:finish, queue_name, job_id}, _from, state = %{conn: conn}) do
    {:ok, result} = Redix.command(conn, ["DEL", job_id])
    remove_backup_job(conn, queue_name, job_id)
    {:reply, :ok, state}
  end

  def handle_call({:resume_inprogress, queue_name}, _from, state = %{conn: conn}) do
    {:ok, length} = Redix.command(conn, ["LLEN", "#{queue_name}:inprogress"])
    if length > 0 do
      Logger.warn "#{queue_name}: resuming #{length} jobs"
    end
    {:ok, job_ids} = Redix.command(conn, ["LRANGE", "#{queue_name}:inprogress", 0, (length - 1)])
    job_ids
    |> Enum.map(fn(job_id) -> restore_backup(conn, queue_name, job_id) end)
    {:reply, :ok, state}
  end

  def handle_call({:remaining_count, queue_name}, _from, state = %{conn: conn}) do
    {:ok, remaining_count} = Redix.command(conn, ["LLEN", "#{queue_name}:waiting"])

    {:reply, {:ok, remaining_count}, state}
  end

  @doc """
  Moves the backed up job into the queue to be processed. This is called once on start
  for each of the unfinished jobs.
  """
  def restore_backup(conn, queue_name, job_id) do
    [_, index] = Redix.pipeline!(
      conn,
      [
        ["LREM", "#{queue_name}:inprogress", 0, job_id],
        ["RPUSH", "#{queue_name}:waiting", job_id]
      ]

    )
    {:ok, index}
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
