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
end
