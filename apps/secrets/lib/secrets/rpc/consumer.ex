defmodule Secrets.Rpc.Consumer do
  @moduledoc """
  EventConsumer is an entry point for secrets requests.
  """

  @behaviour SharedModules.Rpc.MessageProcessing

  use SharedModules.Rpc.MessageProcessing, app_name: :shared_modules

  @mutation "mutation"
  @doc """
  `process_action/1` routes NATS message to the event handler.
  """
  @impl SharedModules.Rpc.MessageProcessing
  def process_action(%{action: action, args: args, private: private, query: query} = context) do
    if String.contains?(query, @mutation) do
      Audit.wrap_operation(
        %{name: action, context: context, trace_id: private[:trace_id]},
        fn operation ->
          {:ok, result} =
            Absinthe.run(query, Secrets.Graph.Schema,
              variables: args,
              context: assign_operation(context, operation)
            )

          Map.put(context, :response, result)
        end
      )
    else
      {:ok, result} =
        Absinthe.run(query, Secrets.Graph.Schema, variables: args, context: context)

      Map.put(context, :response, result)
    end
  end

  defp assign_operation(context, operation),
    do: Map.put(context, :private, Map.put(context.private, :operation, operation))
end
