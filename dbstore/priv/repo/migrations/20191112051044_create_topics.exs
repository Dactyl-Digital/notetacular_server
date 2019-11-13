defmodule Dbstore.Repo.Migrations.CreateTopics do
  use Ecto.Migration

  def change do
    create table("topics") do
      add(:title, :string, null: false)
      add(:tags, {:array, :string}, default: [])
      add(:sub_category_id, references(:sub_categories), on_delete: :delete_all)
      
      timestamps(type: :utc_datetime)
    end
  end
end