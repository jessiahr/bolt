defmodule QueueTest do
  use ExUnit.Case

  test "returns job count" do
    assert Bolt.Queue.jobs_enqueued(:main_queue) == 0
  end

  test "checks out a job" do
    assert Bolt.Queue.checkout_job(:main_queue)
  end

  test "adds a job" do
    assert Bolt.Queue.jobs_enqueued(:main_queue) == 0
    assert Bolt.Queue.enqueue(:main_queue, %{task_param: 1}) == {:ok, 1}
    assert Bolt.Queue.jobs_enqueued(:main_queue) == 1
  end
end
