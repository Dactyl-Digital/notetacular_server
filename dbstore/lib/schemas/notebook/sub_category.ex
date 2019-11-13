defmodule Dbstore.SubCategory do
  use Ecto.Schema
  import Ecto.Changeset

  schema "sub_categories" do
    field(:title, :string)
    
    timestamps()
    belongs_to(:notebooks, Dbstore.Notebook, foreign_key: :notebook_id)
    has_many(:topics, Dbstore.Topic)
  end
  
  def changeset(sub_category, params \\ %{}) do
    sub_category
    |> cast(params, [:title])
    |> validate_required([:title])
    |> validate_length(:title, min: 4, max: 50)
  end
end