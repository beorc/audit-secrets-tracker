defmodule SharedModules.Rpc.Client do
  @receive_timeout_seconds 10

  @callback request_resource(action :: String.t(), resource :: String.t(), query :: String.t(), args :: map, assigns :: map, opts :: list) :: {:ok, any} | {:error, any}

  def request_data(action, query, args, assigns, opts) do
    with {:ok, response} <-
           trace_request(action, opts, fn -> request(action, query, args, assigns, opts) end) do
      {:ok, response[:data]}
    end
  end

  def request_resource(action, resource, query, args, assigns, opts) do
    with {:ok, response} <-
           trace_request(action, opts, fn -> request(action, query, args, assigns, opts) end) do
      {:ok, response[:data][resource]}
    end
  end

  def request_resource(action, query, args, assigns, opts) do
    request_resource(action, action, query, args, assigns, opts)
  end

  def publish(action, body, assigns, opts) do
    message =
      %{
        assigns: assigns,
        body: body
      }
      |> Jason.encode!()

    :ok = Gnat.pub(connection(opts), "#{topic(opts)}.#{action}", message)
  end

  def request(action, query, args, assigns, opts) do
    with {:ok, response} <-
           request_raw(action, query, args, Map.drop(assigns, ~w(app_metadata auth_token)a), opts) do
      response = Jason.decode!(response, keys: :atoms)

      case response do
        response when is_binary(response) ->
          {:ok, response}

        response when is_map(response) ->
          case Map.get(response, :errors) do
            nil -> {:ok, response}
            errors -> {:error, errors}
          end
      end
    end
  end

  defp request_raw(action, query, args, assigns, opts) do
    assigns = Map.put(assigns, :expire_at, System.system_time(:second) + @receive_timeout_seconds)

    message =
      %{
        action: action,
        assigns: assigns,
        query: query,
        args: args
      }
      |> Jason.encode!()

    case Gnat.request(connection(opts), topic(opts), message,
           receive_timeout: @receive_timeout_seconds * 1_000
         ) do
      {:ok, %{body: body}} -> {:ok, body}
      {:error, :timeout} -> {:error, :timeout}
    end
  end

  defp trace_request(action, opts, fnce) do
    case opts[:tracer] do
      nil ->
        fnce.()

      tracer ->
        tracer.trace_request(action, fnce)
    end
  end

  defp connection(opts),
    do: opts[:connection] || SharedModules.Config.nats_connection_name()

  defp topic(opts),
    do: opts[:topic]
end
