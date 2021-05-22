defmodule Secrets.Graph.Schema do
  use Absinthe.Schema

  require Logger

  query do
  end

  mutation do
    @desc "Update password for PostgreSQL user and publish connection config to private topic"
    field :rotate_credentials, type: :string do
      arg :provider, non_null(:string)
      arg :database, non_null(:string)
      arg :username, non_null(:string)

      resolve fn(args, _) ->
        Logger.info(fn -> "[#{args.database}] Password rotation requested..." end)

        with {:config, config} when is_map(config) <- {:config, Secrets.ensure_config!()},
             {:provider_config, provider_config} when is_map(provider_config) <- {:provider_config, config[String.to_atom(args.provider)]},
             :ok <- Secrets.apply_to_provider(Secrets.provider_module(args.provider), :rotate_credentials, [args, provider_config]) do
          SharedModules.Graph.Reply.ok("Succeeded")
        else
          {:error, :function_not_exported} ->
            SharedModules.Graph.Reply.not_found("Provider #{args.provider} not found")
          {:error, [message: message]} ->
            SharedModules.Graph.Reply.unprocessable_entity(details: message)
          {entity, nil} ->
            SharedModules.Graph.Reply.not_found("#{entity} not found")
        end
      end
    end
  end
end
