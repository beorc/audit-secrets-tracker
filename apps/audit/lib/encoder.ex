defimpl Jason.Encoder, for: Audit.Operation do
  defdelegate encode(struct, options), to: SharedModules.Jason.Encoder
end
