defmodule JobStoreTest do
  use ExUnit.Case
  import Mock

  setup do
    Application.stop(:bolt)
    Application.start(:bolt)
    {:ok, conn} = Redix.start_link(Application.get_env(:bolt, :redis_url))
    {:ok, length} = Redix.command(conn, ["FLUSHALL"])
    :ok
  end

  test "starts a job" do
    Bolt.Queue.enqueue(:bg, %{"job_param" => 123})
    {:ok, jid, params} =  Bolt.JobStore.start(:bg)
      assert params ==  %{"job_param" => 123}
  end

  test "finishes a job" do
    Bolt.Queue.enqueue(:bg, %{"job_param" => 123})
    {:ok, jid, params} =  Bolt.JobStore.start(:bg)

      assert Bolt.JobStore.finish(:bg, jid) == :ok
      assert Bolt.JobStore.finish(:bg, "twkjhtkwjehtkh") == :error
  end

  test "adds a job" do
    with_mocks([
      {UUID, [],  [uuid1: fn() ->  "SOMEJOB_ID" end]},
    ]) do
      assert Bolt.JobStore.add(:bg, %{job_param: 12345}) == {:ok, [1, 1]}
    end
  end

  test "adds a list of jobs" do
    with_mocks([
      {UUID, [],  [uuid1: fn() ->  "SOMEJOB_ID" end]},
    ]) do
      assert Bolt.JobStore.add(:bg, [%{job_param: 12345}, %{job_param: 12343}]) == [{:ok}]
    end
  end

end
