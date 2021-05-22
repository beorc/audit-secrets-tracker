defmodule SharedModules.Rpc.Reply do
  def ok(context, result \\ nil) do
    Map.put(context, :response, result)
  end

  def bad_request(context, message \\ "Bad request") do
    Map.put(context, :response, %{errors: [%{message: message}]})
  end

  def unauthenticated(context, message \\ "Unauthenticated") do
    Map.put(context, :response, %{errors: [%{message: message}]})
  end

  def unauthorized(context, message \\ "Unauthorized") do
    Map.put(context, :response, %{errors: [%{message: message}]})
  end

  def not_found(context, message \\ "Not found") do
    Map.put(context, :response, %{errors: [%{message: message}]})
  end

  def gone(context, message \\ "Gone") do
    Map.put(context, :response, %{errors: [%{message: message}]})
  end

  def unprocessable_entity(context, details) do
    Map.put(context, :response, %{errors: [%{message: "Unprocessable entity", details: details}]})
  end

  def internal_server_error(context, details) do
    Map.put(context, :response, %{errors: [%{message: "Internal server error", details: details}]})
  end

  def internal_server_error(context) do
    Map.put(context, :response, %{errors: [%{message: "Internal server error"}]})
  end

  def reply(%{reply_to: reply_to, response: response} = context) do
    connection_name = SharedModules.Config.nats_connection_name()

    case context[:trace] do
      nil ->
        :ok = Gnat.pub(connection_name, reply_to, Jason.encode!(response))

      trace ->
        :ok =
          Gnat.pub(
            connection_name,
            reply_to,
            response |> Map.put(:trace, trace) |> Jason.encode!()
          )
    end

    context
  end

  def reply(_), do: nil
end
