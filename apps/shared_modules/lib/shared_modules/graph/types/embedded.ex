defmodule SharedModules.Graph.Types.Embedded do
  use Absinthe.Schema.Notation

  scalar :embedded do
    parse & &1
    serialize & &1
  end
end
