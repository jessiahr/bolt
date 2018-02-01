defmodule Bolt do
@moduledoc """

[![Build Status](https://travis-ci.org/jessiahr/bolt.svg?branch=master)](https://travis-ci.org/jessiahr/bolt)
[![Hex.pm](https://img.shields.io/hexpm/v/bolt.svg)](https://hex.pm/packages/bolt)


A simple job queue using OTP.


![](https://media.giphy.com/media/3o7TKxJRKk8uPOOdgY/giphy.gif)


## Installation

```elixir
def deps do
  [{:bolt, "~> 0.1.9"}]
end
```
## Usage

For more detail see the [documentation](http://hexdocs.pm/bolt).

### Configure Queues
```elixir
#config.ex
	config :bolt,
	  queues: [{:main, SomeApp.SomeWorker, 10}, {:bg, SomeApp.SomeWorker, 2}],
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
      # Add a single job to the :bg queue
      iex> Bolt.enqueue(:bg, %{"somefield" => 1})
      {:ok, [1, 1]}

      # Add a collection of jobs to the :bg queue
      iex> Bolt.enqueue(:bg, [%{"somefield" => 1}, %{"somefield" => 1}])
      [{:ok}]


### Manage Queues
      # Change worker pools
      iex> Bolt.Queue.set_worker_max(:bg, 5) 
      :ok

      # Pause a queue
      iex> Bolt.Queue.set_worker_max(:bg, 0) 
      :ok


### Web UI
To use the web interface forward to bolt from your router:

```elixir
forward "/bolt", to: Bolt.Router
```
Go to `/bolt` to see the dashboard app


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


![](https://d26dzxoao6i3hh.cloudfront.net/items/0r190p3q22432L3q1h2V/Screen%20Shot%202017-07-19%20at%201.36.29%20PM.png)


### Todo
* More Test Coverage
* More Docs

  """
  defdelegate enqueue(queue_name, job_params), to: Bolt.Queue
  defdelegate status(), to: Bolt.Queue
end
