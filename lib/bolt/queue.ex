defmodule Bolt.Queue do
  use GenServer
  require Logger

  def start_link do
    GenServer.start_link(__MODULE__, %{}, [name: __MODULE__])
  end

  def init(state) do
    Logger.warn "starting! Queue"
    schedulers = Bolt.Scheduler.start_links
    |> Enum.map(fn({name, {:ok, pid}}) -> %{queue_name: name, pid: pid} end)

    {:ok, schedulers}
  end

  @doc """
  Returns the list of schedulers
  """
  def schedulers do
    GenServer.call(__MODULE__, {:schedulers})
  end

  @doc """
  Sets the max worker count for the scheduler.
  """
  def set_worker_max(schedulers_name, worker_max) do
    find_schedulers(schedulers_name)
    |> Map.get(:pid)
    |> Bolt.Scheduler.set_worker_max(worker_max)
  end

  @doc """
  Returns a running queue by name.
  """
  def find_schedulers(schedulers_name) do
    Bolt.Queue.schedulers
    |> Enum.filter(fn(scheduler) -> Atom.to_string(scheduler[:queue_name]) == schedulers_name end)
    |> List.first
  end

  def status do
    Bolt.Queue.schedulers
    |> Enum.map(fn(scheduler) -> Bolt.Scheduler.status(scheduler[:pid]) end)
  end

  def enqueue(queue_name, job_params) do
    if queue_exists?(queue_name) do
      Bolt.JobStore.add(queue_name, job_params)
    else
      {:error, "Undefined Queue"}
    end
  end

  def checkout(queue_name) do
    if queue_exists?(queue_name) do
      Bolt.JobStore.start(queue_name)
    else
      {:error, "Undefined Queue"}
    end
  end

  def resume_inprogress(queue_name) do
    if queue_exists?(queue_name) do
      Bolt.JobStore.resume_inprogress(queue_name)
    else
      {:error, "Undefined Queue"}
    end
  end

  def finish(queue_name, job_id) do
    if queue_exists?(queue_name) do
      Bolt.JobStore.finish(queue_name, job_id)
    else
      {:error, "Undefined Queue"}
    end
  end

  defp queue_exists?(queue_name) do
    Application.get_env(:bolt, :queues)
    |> Enum.map(fn(q) -> elem(q, 0) end)
    |> Enum.member?(queue_name)
  end

  def module_for_queue(queue_name) do
    Application.get_env(:bolt, :queues)
    |> Enum.filter(fn(q)-> elem(q, 0) == queue_name end)
    |> Enum.map(fn(q) -> elem(q, 1) end)
    |> List.last
  end

  def handle_call({:schedulers}, _from, state) do
    {:reply, state, state}
  end

end
