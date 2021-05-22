defmodule SharedModules.Jason.Encoder do
  def encode(%{__struct__: _} = struct, options) do
    struct
    |> to_map()
    |> extend()
    |> encode(options)
  end

  def encode(map, options), do: Jason.Encode.map(map, options)

  def to_map(struct) when is_struct(struct) do
    struct
    |> Map.from_struct()
    |> sanitize()
  end

  def to_map(map) when is_map(map),
    do: map

  def extend(%{inserted_at: inserted_at, updated_at: updated_at} = map) do
    map
    |> Map.delete(:inserted_at)
    |> Map.put(:created_at, encode_date_time(inserted_at))
    |> Map.put(:updated_at, encode_date_time(updated_at))
  end

  def extend(map), do: map

  def encode_date_time(value) do
    case value do
      nil -> nil
      %DateTime{} -> DateTime.to_unix(value, :millisecond)
      value when is_integer(value) -> value
      _ -> value |> DateTime.from_naive!("Etc/UTC") |> DateTime.to_unix(:millisecond)
    end
  end

  def sanitize(map) do
    map
    |> Map.drop([
      :__meta__,
      :__struct__
    ])
    |> Enum.filter(&remove_empty/1)
    |> Enum.into(%{})
  end

  def remove_empty({_, %Ecto.Association.NotLoaded{}}), do: false
  def remove_empty({_, nil}), do: false
  def remove_empty({nil, _}), do: false
  def remove_empty(_), do: true
end

defimpl Jason.Encoder, for: Tuple do
  def encode(tuple, options) do
    tuple
    |> Tuple.to_list()
    |> Jason.Encode.list(options)
  end
end

defimpl Jason.Encoder, for: Spandex.Trace do
  defdelegate encode(struct, options), to: SharedModules.Jason.Encoder
end

defimpl Jason.Encoder, for: [MapSet, Range, Stream] do
  def encode(struct, opts) do
    Jason.Encode.list(Enum.to_list(struct), opts)
  end
end

defimpl Jason.Encoder, for: Ecto.Changeset do
  def encode(changeset, options),
    do: Jason.Encode.map(SharedModules.DB.Ops.errors_on(changeset), options)
end

defimpl Jason.Encoder, for: Spandex.Span do
  alias SharedModules.Jason.Encoder

  def encode(struct, options) do
    map = Encoder.to_map(struct)

    http = map[:http]

    map =
      if http do
        Map.put(map, :http, Enum.into(http, %{}))
      else
        map
      end

    sql_query = map[:sql_query]

    map =
      if sql_query do
        Map.put(map, :sql_query, sql_query |> Enum.into(%{}) |> Map.delete(:db))
      else
        map
      end

    map
    |> Encoder.extend()
    |> Encoder.encode(options)
  end
end
