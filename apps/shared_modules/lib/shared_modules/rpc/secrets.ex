defmodule SharedModules.Rpc.Secrets do
  import SharedModules.Rpc.Client

  @opts [topic: "rpc.Secrets.Actions"]

  def ping,
    do: request(:ping, "", %{}, %{}, @opts)

  @query """
  mutation RotateCredentials($provider: String!, $database: String!, $username: String!) {
    rotate_credentials(provider: $provider, database: $database, username: $username)
  }
  """
  def rotate_credentials(args, opts \\ []),
    do: request_resource(:rotate_credentials, @query, args, %{}, Keyword.merge(@opts, opts))
end
