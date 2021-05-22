defmodule SharedModules.Wait do
  @default_timeout 5_000
  @default_retry_interval 50

  def until(fun), do: until(@default_timeout, fun)

  def until(0, fun) do
    case fun.() do
      nil -> {:error, :timeout}
      result -> {:ok, result}
    end
  end

  def until(timeout, fun) do
    case fun.() do
      nil ->
        :timer.sleep(@default_retry_interval)
        until(max(0, timeout - @default_retry_interval), fun)

      result ->
        {:ok, result}
    end
  end

  def until_bool(fun), do: until_bool(@default_timeout, fun)

  def until_bool(0, fun) do
    case fun.() do
      false -> {:error, :timeout}
      true -> :ok
    end
  end

  def until_bool(timeout, fun) do
    case fun.() do
      false ->
        :timer.sleep(@default_retry_interval)
        until_bool(max(0, timeout - @default_retry_interval), fun)

      true ->
        :ok
    end
  end

  def until_not(fun), do: until_not(@default_timeout, fun)

  def until_not(0, fun) do
    case fun.() do
      nil -> :ok
      _ -> {:error, :timeout}
    end
  end

  def until_not(timeout, fun) do
    case fun.() do
      nil ->
        :ok

      false ->
        :ok

      _ ->
        :timer.sleep(@default_retry_interval)
        until_not(max(0, timeout - @default_retry_interval), fun)
    end
  end
end
