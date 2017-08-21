defmodule Bolt.Worker do
  use GenServer
  require Logger
  @callback work(params :: List.t) :: integer

  def start_link(params, job_id) do
    GenServer.start_link(__MODULE__, %{params: params, job_id: job_id, status: :starting, pid: nil, error: nil})
  end

  def init(state) do
    worker = self()
    pid = spawn(fn() ->
      Logger.debug "#{state[:job_id]} starting"
      job_finished(worker, Bolt.Queue.module_for_queue(:main).work(state[:params]))
      Logger.debug "#{state[:job_id]} finished"
    end)
    Process.monitor(pid)
    {:ok, state |> Map.put(:pid, pid) |> Map.put(:status, :running)}
  end

  def status(worker) do
    GenServer.call(worker, {:status})
  end

  def error(worker) do
    GenServer.call(worker, {:error})
  end

  def teardown(worker) do
    GenServer.stop(worker, :normal)
    false
  end

  def job_finished(worker, result) do
    GenServer.call(worker, {:job_finished, result})
  end

  def handle_call({:status}, _from, state) do
    {:reply, state[:status], state}
  end

  def handle_call({:error}, _from, state) do
    {:reply, state[:error], state}
  end


  def handle_call({:job_finished, result}, from, state) do
    new_state = state
    |> Map.put(:result, result)
    |> Map.put(:status, :finished)

    {:reply, new_state, new_state}
  end
  def handle_info(msg = {:DOWN, ref, tag, pid, :normal}, state), do: {:noreply, state}
  def handle_info(msg = {:DOWN, ref, tag, pid, error}, state) do
    new_state = state
    |> Map.put(:status, :failed)
    |> Map.put(:error, error)
    {:noreply, new_state}
  end
end
