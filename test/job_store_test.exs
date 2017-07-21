defmodule JobStoreTest do
  use ExUnit.Case
  import Mock

  setup do
    Application.stop(:bolt)
    Application.start(:bolt)
    :ok
  end

  def handle_redis_command(command) do
    case command do
      ["RPOP" | _] ->
        {:ok, "bg:jobs:id75ad7556-6e5f-11e7-a394-TEST"}

      ["LPUSH" | _] ->
        {:ok, :ok}

      ["HGET", "bg:jobs:id75ad7556-6e5f-11e7-a394-TEST" | _] ->
        {:ok, Poison.encode!(%{job_param: 123})}

      ["DEL", "bg:jobs:id75ad7556-6e5f-11e7-a394-TEST-DEL" | _] ->
        {:ok, nil}

      ["LREM", "bg:inprogress", 0, "bg:jobs:id75ad7556-6e5f-11e7-a394-TEST-DEL"] ->
        {:ok, nil}

      ["HSET", _, "params", "{\"job_param\":12345}"] ->
        {:ok, nil}
    end
  end

  test "starts a job" do
    with_mocks([
      {Redix, [],  [command: fn(_, command) ->  handle_redis_command(command) end]},
    ]) do
      assert Bolt.JobStore.start(:bg) == {:ok, "bg:jobs:id75ad7556-6e5f-11e7-a394-TEST", %{"job_param" => 123}}
    end
  end

  test "finishes a job" do
    with_mocks([
      {Redix, [],  [command: fn(_, command) ->  handle_redis_command(command) end]},
    ]) do
      assert Bolt.JobStore.finish(:bg, "bg:jobs:id75ad7556-6e5f-11e7-a394-TEST-DEL") == :ok
    end
  end

  test "adds a job" do
    with_mocks([
      {Redix, [],  [command: fn(_, command) ->  handle_redis_command(command) end]},
      {UUID, [],  [uuid1: fn() ->  "SOMEJOB_ID" end]},
    ]) do
      assert Bolt.JobStore.add(:bg, %{job_param: 12345}) == {:ok, "SOMEJOB_ID"}
    end
  end
end
