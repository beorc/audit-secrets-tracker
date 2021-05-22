defmodule SharedModules.Utils do
  def module_compiled?(module),
    do: function_exported?(module, :__info__, 1)

  @spec to_sentence(String.t()) :: String.t()
  @doc "Make sentence from string."
  def to_sentence(string) when is_binary(string) do
    string
    |> Kernel.<>(".")
    |> String.capitalize()
  end

  def intersection(_ids1, []), do: []

  def intersection(ids1, ids2) do
    diff = ids1 -- ids2
    ids1 -- diff
  end

  def intersect?(ids1, ids2),
    do: Enum.any?(intersection(ids1, ids2))

  def to_atom(nil), do: nil
  def to_atom(term) when is_boolean(term), do: term
  def to_atom(term) when is_atom(term), do: term
  def to_atom(term) when is_binary(term), do: String.to_atom(term)

  def to_string(nil), do: nil
  def to_string(term) when is_binary(term), do: term
  def to_string(term) when is_atom(term), do: Atom.to_string(term)

  def to_charlist(nil), do: nil
  def to_charlist(term) when is_list(term), do: term
  def to_charlist(term) when is_binary(term), do: String.to_charlist(term)

  def to_struct(struct, attrs) do
    Enum.reduce(Map.to_list(struct), struct, fn {k, _}, acc ->
      with {:ok, v} <- Map.fetch(attrs, Atom.to_string(k)) do
        %{acc | k => v}
      else
        _ -> acc
      end
    end)
  end

  def map_values_to_charlist(map) do
    map
    |> Enum.map(fn({key, value}) ->
         if is_binary(value) do
           {key, String.to_charlist(value)}
         else
           {key, value}
         end
       end)
    |> Enum.into(%{})
  end

  def map_keys_to_atoms(map) when map_size(map) == 0, do: %{}

  def map_keys_to_atoms(map) do
    for {key, val} <- map, into: %{}, do: {to_atom(key), val}
  end

  def map_keys_to_strings(map) when map_size(map) == 0, do: %{}

  def map_keys_to_strings(map) do
    for {key, val} <- map, into: %{}, do: {__MODULE__.to_string(key), val}
  end

  def deep_map_keys_to_atoms(%{__struct__: _} = entity), do: entity

  def deep_map_keys_to_atoms(map) when is_map(map) do
    for {key, val} <- map, into: %{} do
      cond do
        is_binary(key) -> {to_atom(key), deep_map_keys_to_atoms(val)}
        true -> {key, val}
      end
    end
  end

  def deep_map_keys_to_atoms(value), do: value

  def from_struct(entity) when is_struct(entity) do
    entity
    |> Map.from_struct()
    |> Map.put(:struct, struct_name(entity))
    |> Map.drop([:__meta__, :__struct__])
    |> SharedModules.Jason.Encoder.sanitize()
  end

  def from_struct(entity), do: entity

  def struct_name(%{__struct__: struct}) do
    struct |> Module.split() |> List.last()
  end

  def struct_name(_), do: nil

  def populate_scope(scope, attributes) do
    attributes
    |> Enum.reduce(scope, fn {attribute, value}, acc ->
      if acc[attribute] do
        Map.put(acc, attribute, value)
      else
        acc
      end
    end)
  end

  def mapper(%{__struct__: _, inserted_at: inserted_at} = entity) do
    {:ok, created_at} = DateTime.from_naive(inserted_at, "Etc/UTC")

    entity
    |> from_struct()
    |> Map.drop([
      :inserted_at,
      :updated_at
    ])
    |> Map.put(:created_at, DateTime.to_unix(created_at))
    |> mapper()
  end

  def mapper(%{__struct__: _} = entity) do
    entity
    |> from_struct()
    |> mapper()
  end

  def mapper(entity) when is_map(entity) do
    entity
    |> Enum.filter(fn {_, v} ->
      case v do
        %Ecto.Association.NotLoaded{} -> false
        _ -> true
      end
    end)
    |> Enum.map(fn {k, v} ->
      case v do
        %{calendar: Calendar.ISO} = value -> {k, value}
        %{__struct__: _} = assoc -> {k, mapper(assoc)}
        %{__meta__: _} = assoc -> {k, mapper(assoc)}
        [%{} | _] = value -> {k, Enum.map(value, &mapper/1)}
        value -> {k, value}
      end
    end)
    |> Enum.into(%{})
  end

  def mapper(entity), do: entity
end
