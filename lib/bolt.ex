defmodule Bolt do
  @moduledoc """
  Documentation for Bolt.
  """
  defdelegate enqueue(queue_name, job_params), to: Bolt.Queue
  defdelegate status(), to: Bolt.Queue
end
