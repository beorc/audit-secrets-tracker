import Config

config :secrets,
  config: nil

config :ex_aws,
  secret_access_key: [{:awscli, "default", 30}],
  access_key_id: [{:awscli, "default", 30}],
  awscli_auth_adapter: ExAws.STS.AuthCache.AssumeRoleWebIdentityAdapter,
  json_codec: Jason

config :logger, level: :info
