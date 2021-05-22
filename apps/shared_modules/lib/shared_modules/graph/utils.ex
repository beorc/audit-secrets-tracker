defmodule SharedModules.Graph.Utils do
  def node_name(resolution),
    do: resolution.definition.schema_node.name
end
