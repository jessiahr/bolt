defmodule Bolt.ExampleWorker do
  @behaviour Bolt.Worker
  def work(params) do
    IO.inspect params
  end
end
