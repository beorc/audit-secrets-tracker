defmodule SharedModules.Graph.Reply do
  def ok(entity \\ nil) do
    {:ok, entity}
  end

  def bad_request(message \\ "Bad request", details: _details) do
    {:error, message: message}
  end

  def unauthenticated(message \\ "Unauthenticated") do
    {:error, message: message}
  end

  def unauthorized(message \\ "Unauthorized") do
    {:error, message: message}
  end

  def not_found(message \\ "Not found") do
    {:error, message: message}
  end

  def unprocessable_entity(message \\ "Unprocessable entity", details: details) do
    {:error, message: message, details: details}
  end

  def internal_server_error(message \\ "Internal server error", details: details) do
    {:error, message: message, details: details}
  end
end
