defmodule Bolt.JobStore.Redis do
	def build_add(queue_name, job_params) when is_map(job_params) do
		job_id = UUID.uuid1()
		[
			["HSET", "#{queue_name}:jobs:id#{job_id}", "params", Poison.encode!(job_params)],
			["LPUSH", "#{queue_name}:waiting", "#{queue_name}:jobs:id#{job_id}"]
		]
	end
	def build_finish(queue_name, job_id) do
		[
			# remove job ID from list
			["LREM", "#{queue_name}:inprogress", 0, job_id],
			# delete job data
			["DEL", job_id]
		]
		
	end
	def to_transaction(commands) do
		[["MULTI"]] ++ commands ++ [["EXEC"]]
	end
end