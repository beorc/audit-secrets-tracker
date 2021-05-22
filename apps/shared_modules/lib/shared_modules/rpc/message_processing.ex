defmodule SharedModules.Rpc.MessageProcessing do
  @type reply :: map
  @type context :: map

  @callback process_action(context) :: reply
  @callback process_ping(context) :: reply

  defmacro __using__(app_name: _app_name) do
    quote location: :keep do
      require Logger
      import SharedModules.Rpc.Reply
      alias SharedModules.Utils

      @action "action"
      @args "args"
      @assigns "assigns"
      @query "query"
      @required_attrs [@action, @args, @assigns, @query]
      @ping "ping"

      def process_message(%{reply_to: reply_to, body: body} = req) do
        context =
          with message <- Jason.decode!(body),
              {:missing_attrs, []} <- {:missing_attrs, missing_required_attributes(message, @action)},
              %{@action => action} <- message do
            context = %{
              reply_to: reply_to,
              action: action
            }

            if @ping == action do
              process_ping(context)
            else
              with [] <- missing_required_attributes(message, [@args, @assigns, @query]) do
                %{@args => args, @assigns => assigns, @query => query} = message
                context
                |> Map.put(:args, args)
                |> Map.put(:private, SharedModules.Utils.map_keys_to_atoms(assigns))
                |> Map.put(:query, query)
                |> check_expired()
                |> perform_processing()
              else
                missing_attrs ->
                  bad_request(%{reply_to: reply_to}, "Missing attribute(s): #{Enum.join(missing_attrs, ",")}")
              end
            end
          else
            {:missing_attrs, missing_attrs} ->
              bad_request(%{reply_to: reply_to}, "Missing attribute(s): #{Enum.join(missing_attrs, ",")}")
          end

        reply(context)
      end

      defp missing_required_attributes(message, required_attrs) when is_list(required_attrs) do
        missing_attrs =
          required_attrs
          |> Enum.map(fn(attr) ->
          if is_nil(Map.get(message, attr)) do
            attr
          else
            nil
          end
        end)
        |> Enum.reject(&is_nil/1)
      end

      defp missing_required_attributes(message, required_attribute) when is_binary(required_attribute),
        do: missing_required_attributes(message, [required_attribute])

      defp perform_processing({:error, :expired, context}),
        do: bad_request(%{reply_to: context.reply_to, action: context.action}, "expired request")

      defp perform_processing(context) do
        Logger.debug("Processing #{context.action}...")

        # TODO add/check locale
        # assigns = %{locale: Map.get(assigns || %{}, "locale", "en")}
        # context = context |> Map.put(:assigns, assigns)

        process_action(context)
      end

      def process_ping(context) do
        ok(context, "pong")
      end

      defoverridable process_ping: 1

      defp check_expired(context) do
        case is_expired?(context) do
          false -> context
          true -> {:error, :expired, context}
        end
      end

      defp is_expired?(%{private: private}) do
        private[:expire_at] < System.system_time(:second)
      end

      defp is_expired?(_), do: false
    end
  end
end
