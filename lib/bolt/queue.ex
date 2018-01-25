defmodule Bolt.Queue do
  @moduledoc """
  Queue is the primary module to interact with the job queue.
  """
  use GenServer
  require Logger

  @doc """
  Start a new Queue which can contain may schedulers
  """
  def start_link do
    GenServer.start_link(__MODULE__, [], [name: __MODULE__])
  end

  @doc """
  initializes the queue by starting each of the schedulers defined in the config.
  """
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
  def find_schedulers(schedulers_name) when is_atom(schedulers_name) do
    schedulers_name
    |> Atom.to_string
    |> find_schedulers
  end

  @doc """
  Returns a running queue by name.
  """
  def find_schedulers(schedulers_name) when is_binary(schedulers_name) do
    Bolt.Queue.schedulers
    |> Enum.filter(fn(scheduler) -> Atom.to_string(scheduler[:queue_name]) == schedulers_name end)
    |> List.first
  end

  @doc """
  Returns a the status for each scheduler and its workers.
  """
  def status do
    Bolt.Queue.schedulers
    |> Enum.map(fn(scheduler) -> Bolt.Scheduler.status(scheduler[:pid]) end)
  end

  @doc """
  Adds a job to the queue if it exists.
  """
  def enqueue(queue_name, job_params) when is_map(job_params) do
    if queue_exists?(queue_name) do
      Bolt.JobStore.add(queue_name, job_params)
    else
      {:error, "Undefined Queue"}
    end
  end

  @doc """
  Adds a list of jobs to the queue if it exists.
  """
  def enqueue(queue_name, job_params) when is_list(job_params) do
    if queue_exists?(queue_name) do
      Bolt.JobStore.add(queue_name, job_params)
    else
      {:error, "Undefined Queue"}
    end
  end

  @doc """
  Checksout the next job from the queue if it exists. This will copy the job to the inprogress backup
  to protect against lost jobs.
  """
  def checkout(queue_name) do
    if queue_exists?(queue_name) do
      Bolt.JobStore.start(queue_name)
    else
      {:error, "Undefined Queue"}
    end
  end

  @doc """
  Pulls all inprogress jobs for this queue back into the queue to be run immediately.
  """
  def resume_inprogress(queue_name) do
    if queue_exists?(queue_name) do
      Bolt.JobStore.resume_inprogress(queue_name)
    else
      {:error, "Undefined Queue"}
    end
  end

  @doc """
  Marks a job as finished. It will be removed from inprogress and its job data will be removed.
  """
  def finish(queue_name, job_id) do
    if queue_exists?(queue_name) do
      Bolt.JobStore.finish(queue_name, job_id)
    else
      {:error, "Undefined Queue"}
    end
  end

  @doc """
  Checks if a queue name is defined in the config.
  """
  defp queue_exists?(queue_name) do
    Application.get_env(:bolt, :queues)
    |> Enum.map(fn(q) -> elem(q, 0) end)
    |> Enum.member?(queue_name)
  end

  @doc """
  Returns the worker module assigned in the config for a queue.
  """
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
