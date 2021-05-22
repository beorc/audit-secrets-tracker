defmodule Secrets.Graph.Types do
  use Absinthe.Schema.Notation

  object :postgresql_account do
    field :host, :string
    field :database, :string
    field :port, :integer
    field :username, :string
    field :password, :string
  end
end
