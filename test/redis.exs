defmodule RedisTest do
  use ExUnit.Case
  import Mock

  setup do
    Application.stop(:bolt)
    Application.start(:bolt)
    {:ok, conn} = Redix.start_link(Application.get_env(:bolt, :redis_url))
    {:ok, length} = Redix.command(conn, ["FLUSHALL"])
    :ok
  end

  test "builds a job add querry" do
    with_mocks([
      {UUID, [],  [uuid1: fn() ->  "SOMEJOB_ID" end]},
    ]) do
      assert Bolt.JobStore.Redis.build_add(:bg, [%{job_param: 12345}]) == [{:ok, "SOMEJOB_ID"}]
    end
  end
end
