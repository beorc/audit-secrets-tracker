defmodule SharedModules.Jason.Extender do
  def extend(entities, fnce) when is_list(entities),
    do: Enum.map(entities, &SharedModules.Jason.Extender.extend(&1, fnce))

  def extend(%{__struct__: _} = entity, fnce) do
    entity
    |> fnce.()
    |> extend()
    |> SharedModules.Jason.Encoder.to_map()
    |> Enum.map(&extend(&1, fnce))
    |> Enum.into(%{})
  end

  def extend(entity, _) when is_map(entity),
    do: extend(entity)

  def extend(entity, _),
    do: entity

  def extend(%{inserted_at: inserted_at, updated_at: updated_at} = entity) do
    entity
    |> Map.delete(:inserted_at)
    |> Map.put(:created_at, SharedModules.Jason.Encoder.encode_date_time(inserted_at))
    |> Map.put(:updated_at, SharedModules.Jason.Encoder.encode_date_time(updated_at))
    |> SharedModules.Jason.Encoder.to_map()
  end

  def extend(entity),
    do: entity
end
