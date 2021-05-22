defmodule SharedModules.Rpc.Policies do
  def enforce(:permissions, %{private: %{permissions: permissions}}) when is_list(permissions),
    do: :ok

  def enforce(:permissions, _context), do: false

  def enforce(:current_user, %{assigns: %{current_user: _}}), do: :ok
  def enforce(:current_user, _context), do: false

  def enforce(:authenticated, context) do
    with :ok <- enforce_private(:permissions, context) do
      enforce_private(:authenticated, context)
    end
  end

  def enforce(entity, %{assigns: assigns}) when is_atom(entity) do
    case assigns[entity] do
      nil -> :not_found
      result when is_atom(result) -> result
      _ -> :ok
    end
  end

  def enforce_private(entity, %{private: private}) when is_atom(entity) do
    case private[entity] do
      nil -> false
      false -> false
      _ -> :ok
    end
  end
end
