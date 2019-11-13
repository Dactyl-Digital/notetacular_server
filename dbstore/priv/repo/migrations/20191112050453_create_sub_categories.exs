defmodule Dbstore.Repo.Migrations.CreateSubCategories do
  use Ecto.Migration

  def change do
    create table("sub_categories") do
      add(:title, :string, null: false)
      add(:notebook_id, references(:notebooks), on_delete: :delete_all)
      
      timestamps(type: :utc_datetime)
    end
  end
end