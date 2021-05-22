defmodule Tracker.Tasks do
  def migrate do
    SharedModules.DB.Ops.migrate(:tracker)

    :init.stop()
  end
end
