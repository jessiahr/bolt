# Bolt [![Build Status](https://travis-ci.org/jessiahr/bolt.svg?branch=master)](https://travis-ci.org/jessiahr/bolt)

A simple job queue using OTP.


![](https://d26dzxoao6i3hh.cloudfront.net/items/012M0D3L1w462P1m2H3s/giphy-tumblr.gif)


## Installation

```elixir
def deps do
  [{:bolt, "~> 0.1.4"}]
end
```
## Usage

### Configure Queues
```elixir
#config.ex
config :bolt,
  queues: [{:main, SomeApp.SomeWorker}, {:main, SomeApp.SomeWorker}],
  redis_url: "redis://localhost:6379",
  port: 3000
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

### Use The API
`GET localhost:3000/` change the port by setting in config or set to nil to disable endpoint.
```json
[
  {
    "workers": [],
    "worker_max": 1,
    "status": "running",
    "queue_name": "main",
    "jobs_remaining": 0
  },
  {
    "workers": [
      {
        "status": "finished",
        "started_at": "2017-07-08T00:04:49.773760Z",
        "job_id": "bg:jobs:id69050946-636e-11e7-bd14-784f437e1c56"
      }
    ],
    "worker_max": 1,
    "status": "running",
    "queue_name": "bg",
    "jobs_remaining": 167804
  }
]
```

### Manage Queues

Forward `/bolt` to the `Bolt.Router`

```elixir
forward "/bolt", to: Bolt.Router
```
Go to `/bolt` to see the dashboard app


![](https://d26dzxoao6i3hh.cloudfront.net/items/0r190p3q22432L3q1h2V/Screen%20Shot%202017-07-19%20at%201.36.29%20PM.png)


### Todo
* Test Coverage
* Docs
