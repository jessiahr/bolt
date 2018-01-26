defmodule BoltTest do
  use ExUnit.Case
  import Mock
  doctest Bolt
	setup do
    Application.stop(:bolt)
    Application.start(:bolt)
    {:ok, conn} = Redix.start_link(Application.get_env(:bolt, :redis_url))
    {:ok, length} = Redix.command(conn, ["FLUSHALL"])
    :ok
  end
   test "enqueues a job when queue does exist" do
    with_mocks([
      {Bolt.JobStore, [],  [add: fn(_, _) -> {:ok, "job_id"} end]}
    ]) do
      result = Bolt.enqueue(:main, %{a: 1, b: [2, 3]})
      assert called Bolt.JobStore.add(:main, %{a: 1, b: [2, 3]})
      assert result == {:ok, "job_id"}
    end
  end

    test "enqueues a list of jobs when queue does exist" do
    with_mocks([
      {Bolt.JobStore, [],  [add: fn(_, _) -> [{:ok, "job_id1"}, {:ok, "job_id1"}] end]}
    ]) do
      result = Bolt.enqueue(:main, [%{a: 1, b: [2, 3]}, %{a: 1, b: [2, 3]}])
      assert called Bolt.JobStore.add(:main, [%{a: 1, b: [2, 3]}, %{a: 1, b: [2, 3]}])
      assert result == [ok: "job_id1", ok: "job_id1"]
    end
  end
end
