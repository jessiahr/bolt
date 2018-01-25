defmodule Bolt.JobStore.Redis do
	def build_add(queue_name, job_params) do
    job_id = UUID.uuid1()
    [
      ["HSET", "#{queue_name}:jobs:id#{job_id}", "params", Poison.encode!(job_params)],
      ["LPUSH", "#{queue_name}:waiting", "#{queue_name}:jobs:id#{job_id}"]
    ]
  end
end