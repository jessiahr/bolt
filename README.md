# Bolt

A simple job queue using OTP.


![](https://d26dzxoao6i3hh.cloudfront.net/items/012M0D3L1w462P1m2H3s/giphy-tumblr.gif)


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
