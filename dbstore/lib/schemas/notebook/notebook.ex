defmodule Dbstore.Notebook do
  use Ecto.Schema
  import Ecto.Changeset

  schema "notebooks" do
    field(:title, :string)
    
    timestamps()
    belongs_to(:users, Dbstore.User, foreign_key: :owner_id)
    has_many(:sub_categories, Dbstore.SubCategory)
  end
  
  def changeset(notebook, params \\ %{}) do
    notebook
    |> cast(params, [:title, :owner_id])
    |> validate_required([:title, :owner_id])
    |> validate_length(:title, min: 4, max: 50)
  end
end