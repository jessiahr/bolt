defmodule QueueTest do
  use ExUnit.Case
  import Mock

  setup do
    Application.start(:bolt)
    {:ok, conn} = Redix.start_link(Application.get_env(:bolt, :redis_url))
    {:ok, length} = Redix.command(conn, ["FLUSHALL"])
    :ok
  end

  test "initializes propperly" do
    Application.stop(:bolt)
    queue = Bolt.Queue.start_link
    assert elem(queue, 0) == :ok
  end

  test "returns schedulers" do
    schedulers = Bolt.Queue.schedulers
    assert length(schedulers) == 2
  end

  test "finds a scheduler by string name" do
    with_mocks([
      {Bolt.Scheduler, [],  [start_links: fn() -> [{:q1, {:ok, nil}}, {:q2, {:ok, nil}}] end]}
    ]) do
      Application.stop(:bolt)
      Application.start(:bolt)
      IO.inspect Bolt.Queue.schedulers
      assert Bolt.Queue.find_schedulers("q2") == %{queue_name: :q2, pid: nil}
    end
  end

  test "finds a scheduler by atom name" do
    with_mocks([
      {Bolt.Scheduler, [],  [start_links: fn() -> [{:q1, {:ok, nil}}, {:q2, {:ok, nil}}] end]}
    ]) do
      Application.stop(:bolt)
      Application.start(:bolt)
      IO.inspect Bolt.Queue.schedulers
      assert Bolt.Queue.find_schedulers(:q2) == %{queue_name: :q2, pid: nil}
    end
  end

  test "does not enqueues a job when queue does not exist" do
    with_mocks([
      {Bolt.JobStore, [],  [add: fn(_, _) -> nil end]}
    ]) do
      Bolt.Queue.enqueue(:not_a_real_q, %{a: 1, b: [2, 3]})
      refute called Bolt.JobStore.add(:not_a_real_q, %{a: 1, b: [2, 3]})
    end
  end

  test "enqueues a job when queue does exist" do
    with_mocks([
      {Bolt.JobStore, [],  [add: fn(_, _) -> {:ok, "job_id"} end]}
    ]) do
      result = Bolt.Queue.enqueue(:main, %{a: 1, b: [2, 3]})
      assert called Bolt.JobStore.add(:main, %{a: 1, b: [2, 3]})
      assert result == {:ok, "job_id"}
    end
  end

    test "enqueues a list of jobs when queue does exist" do
    with_mocks([
      {Bolt.JobStore, [],  [add: fn(_, _) -> [{:ok, "job_id1"}, {:ok, "job_id1"}] end]}
    ]) do
      result = Bolt.Queue.enqueue(:main, [%{a: 1, b: [2, 3]}, %{a: 1, b: [2, 3]}])
      assert called Bolt.JobStore.add(:main, [%{a: 1, b: [2, 3]}, %{a: 1, b: [2, 3]}])
      assert result == [ok: "job_id1", ok: "job_id1"]
    end
  end

  test "enqueues a large list of jobs when queue does exist" do
    test_size = 100000
    assert Bolt.JobStore.remaining_count(:main) == {:ok, 0}
    jobs = for n <- 1..test_size do
      %{a: 1, b: [2, 3]}
    end 
    result = Bolt.Queue.enqueue(:main, jobs)

   assert Bolt.JobStore.remaining_count(:main) == {:ok, test_size}
  end

  test "checks out a job" do
    with_mocks([
      {Bolt.JobStore, [],  [start: fn(_) -> %{job_param: 1} end]}
    ]) do
      job = Bolt.Queue.checkout(:main)
      assert job == %{job_param: 1}
    end
  end

  test "finishes out a job" do
    with_mocks([
      {Bolt.JobStore, [],  [finish: fn(_, _) -> :ok end]}
    ]) do
      result = Bolt.Queue.finish(:main, "somejob_id")
      assert result == :ok
    end
  end
end
