defmodule Dbstore.Repo.Migrations.CreateCredential do
  use Ecto.Migration

  def change do
    create table("credentials") do
      add(:email, :string, null: false)
      add(:password_hash, :string, null: false)
      add(:hashed_remember_token, :string)
      add(:user_id, references(:users), on_delete: :delete_all, null: false)
      # add(:privileges, {:array, :string}, default: [])
      
      timestamps(type: :utc_datetime)
    end
    
    create(unique_index("credentials", :email))
    create(index("credentials", :user_id))
  end
end
