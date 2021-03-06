defmodule Bolt.JobStore do
  @chunk_size 1000

  use GenServer
  require Logger
  #https://stackoverflow.com/questions/22001247/redis-how-to-store-associative-array-set-or-hash-or-list

  def start_link do
    GenServer.start_link(__MODULE__, %{}, [name: __MODULE__])
  end

  def add(queue_name, job_params) when is_map(job_params) do
    GenServer.call(__MODULE__, {:add, queue_name, job_params})
  end 

  def add(queue_name, job_list) when is_list(job_list) do
    Stream.chunk(job_list, @chunk_size, @chunk_size, []) 
    |> Stream.map(fn(job_set) ->
      commands_for_chunk = Enum.reduce(job_set, [], fn(job, acc) -> 
        Bolt.JobStore.Redis.build_add(queue_name, job) ++ acc
      end)
      |> Bolt.JobStore.Redis.to_transaction
      Logger.info "Bolt: Sending chunk"
      GenServer.call(__MODULE__, {:add_list, commands_for_chunk})
    end)
    |> Enum.uniq
  end

  def start(queue_name) do
    GenServer.call(__MODULE__, {:start, queue_name})
  end

  def failed(queue_name, job_id, error) do
    GenServer.call(__MODULE__, {:failed, queue_name, job_id, error})
  end

  @doc """
  Get the latest set of failed jobs for this queue.
  """
  def failed_list(queue_name) do
    GenServer.call(__MODULE__, {:failed_list, queue_name})
  end

  @doc """
  Get the number of failed jobs for this queue.
  """
  def failed_count(queue_name) do
    GenServer.call(__MODULE__, {:failed_count, queue_name})
  end

  @doc """
  Gets the details of a given failed job id.
  """
  def failed_details(queue_name, job_id) do
    GenServer.call(__MODULE__, {:failed_details, queue_name, job_id})
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

  def init(_) do
    case Redix.start_link(Application.get_env(:bolt, :redis_url)) do
      {:ok, conn} ->
          Logger.warn "Starting! JobStore"
        {:ok, %{conn: conn}}
      other ->
        raise other
        {:error, "Something went wrong"}
    end
  end

  defp decode_job(nil), do: nil
  defp decode_job(job) do
    Poison.decode!(job)
  end

  def handle_call({:add, queue_name, job_params}, _from, state = %{conn: conn}) do
    command_list = Bolt.JobStore.Redis.build_add(queue_name, job_params) 
    result = Redix.pipeline!(conn, command_list)

    {:reply, {:ok, result}, state}
  end  

  def handle_call({:add_list, command_list}, _from, state = %{conn: conn}) do
    Redix.pipeline!(conn, command_list)
    {:reply, {:ok}, state}
  end

  def handle_call({:failed, queue_name, job_id, error}, _from, state = %{conn: conn}) do
    {:ok, job_params} = Redix.command(conn, ["HGET", job_id, "params"])
    job_guid = job_id |> String.split(":") |> List.last
    Redix.pipeline!(
      conn,
      [
        # remove the first instance found of this job id from the inprogress list
        ["LREM", "#{queue_name}:inprogress", 0, job_id],
        
        # remove the job params 
        ["DEL", "#{queue_name}:jobs:#{job_guid}"],

        # save the failed job params and error 
        ["HSET", "#{queue_name}:failed:#{job_guid}", "params", job_params],
        ["HSET", "#{queue_name}:failed:#{job_guid}", "error", error],
        
        # add the job id to the failed list
        ["RPUSH", "#{queue_name}:failed", job_guid]
      ]
    )
    {:reply, {:ok}, state}
  end
  
  def handle_call({:finish, queue_name, job_id}, _from, state = %{conn: conn}) do
    commands = Bolt.JobStore.Redis.build_finish(queue_name, job_id)
    |> Bolt.JobStore.Redis.to_transaction
    result = Redix.pipeline!(conn, commands)

    case result do
      ["OK", "QUEUED", "QUEUED", [1, 1]] -> 
        {:reply, :ok, state}
      other ->
        IO.inspect other
        {:reply, :error, state}  
    end
  end

  def handle_call({:start, queue_name}, _from, state = %{conn: conn}) do
    {:ok, job_id} = Redix.command(conn, ["RPOP", "#{queue_name}:waiting"])
    if job_id != nil do
      backup_job(conn, queue_name, job_id)
      {:ok, job} = Redix.command(conn, ["HGET", job_id, "params"])
      {:reply, {:ok, job_id, decode_job(job)}, state} 
    else
      {:reply, {:nojob}, state} 
    end
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
  GenServer handler for getting the latest set of failed jobs for this queue.
  """
  def handle_call({:failed_list, queue_name}, _from, state = %{conn: conn}) do
    {:ok, failed_jobs} = Redix.command(conn, ["LRANGE", "#{queue_name}:failed", -100, -1])
    {:reply, {:ok, failed_jobs}, state}
  end 


  @doc """
  GenServer handler for getting the number of failed jobs for a given queue.
  """
  def handle_call({:failed_count, queue_name}, _from, state = %{conn: conn}) do
    {:ok, failed_count} = Redix.command(conn, ["LLEN", "#{queue_name}:failed"])
    {:reply, failed_count, state}
  end  

  @doc """
  GenServer handler for getting the details of a given failed job
  """
  def handle_call({:failed_details, queue_name, job_id}, _from, state = %{conn: conn}) do
    {:ok, failed_job} = Redix.command(conn, ["HGETALL", "#{queue_name}:failed:#{job_id}"])
    {:reply, {:ok, failed_job}, state}
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

  def backup_job(_, _, nil), do: nil
  def backup_job(conn, queue_name, job_id) do
    Redix.command(conn, ["LPUSH", "#{queue_name}:inprogress", job_id])
  end
end
