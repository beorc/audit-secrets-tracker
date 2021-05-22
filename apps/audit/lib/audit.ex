defmodule Audit do
  @moduledoc """
  Documentation for Audit.
  """

  import SharedModules.DB.Ops, only: [errors_on: 1]

  def repo,
    do: Audit.Repo

  def wrap(attrs, fnce) do
    result =
      Audit.repo().transaction(fn ->
        try do
          fnce.()
        rescue
          exception ->
            Audit.insert(attrs |> Map.put(:outcome, exception) |> Map.put(:success, false))

            reraise exception, __STACKTRACE__
        else
          result ->
            case result do
              {:ok, outcome} ->
                Audit.insert(attrs |> Map.put(:outcome, outcome) |> Map.put(:success, true))

                result

              {:error, _failed_operation, _failed_value, changeset} ->
                Audit.insert(
                  attrs
                  |> Map.put(:outcome, errors_on(changeset))
                  |> Map.put(:success, false)
                )

                result

              {:error, :validation_failure, errors} ->
                Audit.insert(attrs |> Map.put(:outcome, errors) |> Map.put(:success, false))

                result

              {:error, %{errors: _} = changeset} ->
                Audit.insert(
                  attrs
                  |> Map.put(:outcome, errors_on(changeset))
                  |> Map.put(:success, false)
                )

                result
            end
        end
      end)

    case result do
      {:ok, outcome} -> outcome
      {:error, _} = error -> error
    end
  end

  def insert(attrs) do
    attrs
    |> Map.put(:state, SharedModules.Utils.mapper(Map.get(attrs, :state)))
    |> Map.put(:outcome, SharedModules.Utils.mapper(Map.get(attrs, :outcome)))
    |> Map.put(:organization_ids, List.wrap(Map.get(attrs, :organization_ids, [])))
    |> Audit.Transaction.changeset()
    |> Audit.repo().insert!()
  end

  def insert(command, outcome, options) when is_map(command) and is_map(outcome) do
    %{
      input: SharedModules.Utils.mapper(command),
      outcome: SharedModules.Utils.mapper(outcome),
      name: SharedModules.Utils.struct_name(command),
      parent_id: Map.get(options, :parent_id),
      audit_operation_id: operation(options).id
    }
    |> Audit.Record.changeset()
    |> Audit.repo().insert!()
  end

  def insert(command, outcome, options) when is_tuple(outcome) do
    insert(command, %{error: Tuple.to_list(outcome)}, options)
  end

  def insert(command, outcome, options) do
    insert(command, %{error: Kernel.to_string(outcome)}, options)
  end

  defp insert_operation!(attrs) do
    attrs
    |> Audit.Operation.changeset()
    |> Audit.repo().insert!()
  end

  defp update_operation!(operation, attrs) do
    operation
    |> Audit.Operation.update_changeset(attrs)
    |> Audit.repo().update!()
  end

  def wrap_operation(attrs, fnce) do
    operation = insert_operation!(attrs)

    try do
      fnce.(operation)
    rescue
      exception ->
        params = %{
          error: Exception.message(exception),
          exception: Exception.format(:error, exception, __STACKTRACE__)
        }

        update_operation!(operation, params)

        reraise exception, __STACKTRACE__
    else
      result ->
        params = %{
          response: result.response
        }

        update_operation!(operation, params)

        result
    end
  end

  defp operation(attrs) do
    operation = Map.get(attrs, :operation) || Map.get(attrs, "operation")

    case operation do
      nil -> %{id: nil}
      operation -> operation
    end
  end
end
