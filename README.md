# Bolt

**TODO: Add description**

## Installation

```elixir
def deps do
  [{:bolt, "~> 0.1.0"}]
end
```
## Usage

### Configure Queues
```elixir
#config.ex
config :bolt,
  queues: [{:main, SomeApp.SomeWorker}, {:main, SomeApp.SomeWorker}],
  redis_url: "redis://localhost:6379"
```

### Define a Worker
```elixir
defmodule SomeApp.SomeWorker do
  @behaviour Bolt.Worker
  def work(params) do
    #Do some work!
  end
end
```


### Enqueue Jobs
```elixir
 Bolt.Queue.enqueue(:bg, %{a: 1, b: 2})
```
