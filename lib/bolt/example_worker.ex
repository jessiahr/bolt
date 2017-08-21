defmodule Bolt.ExampleWorker do
  @behaviour Bolt.Worker
  def work(params) do

    raise "oops"
  end
end
