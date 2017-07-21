# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :bolt,
  queues: [{:main, Bolt.ExampleWorker, 0}, {:bg, Bolt.ExampleWorker, 0}],
  redis_url: "redis://localhost:6379",
  port: nil
