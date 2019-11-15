defmodule Dbstore.Topic do
  use Ecto.Schema
  import Ecto.Changeset
  # alias Dbstore.{Credential, Membership}

  schema "topics" do
    field(:title, :string)
    field(:tags, {:array, :string})

    timestamps()
    belongs_to(:sub_categories, Dbstore.Topic, foreign_key: :sub_category_id)
    has_many(:notes, Dbstore.Note)
  end

  def changeset(topic, params \\ %{}) do
    topic
    |> cast(params, [:title, :sub_category_id])
    |> validate_required([:title, :sub_category_id])
    |> validate_length(:title, min: 4, max: 50)
  end
end
