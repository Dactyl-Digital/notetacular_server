defmodule Dbstore.Repo.Migrations.CreateBilling do
  use Ecto.Migration

  def change do
    create table("billings") do
      add(:stripe_customer_id, :string)
      add(:stripe_currency, :string)
      add(:user_id, references(:users), on_delete: :delete_all, null: false)
      
      timestamps(type: :utc_datetime)
    end
    
    create(unique_index("billings", :stripe_customer_id))
    create(index("billings", :user_id))
  end
end
