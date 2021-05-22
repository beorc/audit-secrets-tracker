import Config

config :tracker,
  ecto_repos: [Tracker.Repo]

import_config "#{Mix.env()}.exs"
