defmodule Bolt.Scheduler do
  @worker_count 10
  @interval 1000
  use GenServer
  require Logger

  def start_link(queue_name) do
    GenServer.start_link(__MODULE__, %{queue_name: queue_name, workers: [], status: :starting})
  end

  def start_links do
    Application.get_env(:bolt, :queues)
    |> Enum.map(fn(queue) -> elem(queue, 0) end)
    |> Enum.map(fn(queue_name) -> {queue_name, start_link(queue_name)} end)
  end

  def init(state) do
    Logger.warn "starting! Scheduler"
    schedule_next_work()
    {:ok, state}
  end

  def handle_info(:schedule_work, state = %{status: :starting}) do
    Logger.warn "init #{state[:queue_name]}"
    Bolt.Queue.resume_inprogress(state[:queue_name])
    schedule_next_work()
    {:noreply, state |> Map.put(:status, :running)}
  end

  def handle_info(:schedule_work, state) do
    new_state = state
    |> teardown_workers
    |> fill_workers

    schedule_next_work()
    {:noreply, new_state }
  end

  def teardown_workers(state) do
    workers = Map.get(state, :workers)
    |> Enum.filter(fn(worker) ->
      case Bolt.Worker.status(worker[:process]) do
        :running ->
          true
        :starting ->
          true
        :finished ->
          Bolt.Queue.finish(state[:queue_name], worker[:job_id])
          Bolt.Worker.teardown(worker[:process])
        :failed ->
          Logger.warn "Worker failed and will be recycled"
          Bolt.Worker.teardown(worker[:process])
      end
    end)
    state
    |> Map.put(:workers, workers)
  end

  def fill_workers(state = %{workers: workers, queue_name: queue_name}) do
    new_workers = (@worker_count - Enum.count(workers))
    |> build_workers(queue_name)
    workers ++ new_workers
    Map.put(state, :workers, new_workers)
  end

  def build_workers(0, _), do: []

  def build_workers(count, queue_name) do
    {:ok, job_id, job} = Bolt.Queue.checkout(queue_name)
    case job_id do
      nil ->
        []
      _ ->
        {:ok, worker} = Bolt.Worker.start_link(job, job_id)
        [%{process: worker, job_id: job_id, started_at: Timex.now} | build_workers(count - 1, queue_name)]
    end
  end

  defp schedule_next_work() do
    Process.send_after(self(), :schedule_work, @interval) # In 2 hours
  end
end
