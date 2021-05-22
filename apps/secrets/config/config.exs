# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
import Config

config :shared_modules, :mq, profile: :simple

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

import_config "#{Mix.env()}.exs"
