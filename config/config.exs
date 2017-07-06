# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :bolt,
  queues: [{:main, Bolt.ExampleWorker}, {:bg, Bolt.ExampleWorker}],
  redis_url: "redis://localhost:6379"
