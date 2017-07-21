defmodule WorkerTest do
  use ExUnit.Case
  import Mock

  setup do
    Application.start(:bolt)
    :ok
  end
end
