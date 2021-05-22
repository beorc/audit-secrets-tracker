defimpl Jason.Encoder, for: Tracker.Task do
  defdelegate encode(struct, options), to: SharedModules.Jason.Encoder
end
