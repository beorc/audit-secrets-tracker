defmodule Secrets do
  @secret_name "secrets_config"
  @prefix "Elixir.Secrets"
  @dot "."

  require Logger

  def ensure_config! do
    case Application.get_env(:secrets, :config) do
      nil ->
        refetch_config!()
      config when is_binary(config) ->
        config
          |> update_config!()
          |> apply_config_to_provider!()
      config when is_map(config) ->
        config
    end
  end

  def refetch_config! do
    get_config!()
    |> update_config!()
    |> apply_config_to_provider!()
  end

  def update_config!(config) do
    config = Jason.decode!(config, keys: :atoms)

    :ok = Application.put_env(:secrets, :config, config)

    config
  end

  def apply_config_to_provider!(config) do
    try do
      result =
        config
        |> Map.keys()
        |> Enum.map(&apply_to_provider(provider_module(&1), :apply_config, [config]))

      {:ok, result}
    rescue
      e ->
        Logger.error(fn -> "Error on config application: #{inspect(e)}" end)
        {:error, e}
    end
  end

  def provider_module(provider) do
    Enum.join([@prefix, provider |> SharedModules.Utils.to_string() |> String.capitalize()], @dot)
    |> String.to_atom()
  end

  @spec apply_to_provider(atom(), atom()) :: {:ok, term()} | {:error, :function_not_exported}
  def apply_to_provider(module, function_name, arguments \\ []) do
    if function_exported?(module, function_name, length(arguments)) do
      apply(module, function_name, arguments)
    else
      {:error, :function_not_exported}
    end
  end

  def get_config! do
    %{"SecretString" => config} =
      ExAws.SecretsManager.get_secret_value(@secret_name) |> ExAws.request!()

    config
  end
end
