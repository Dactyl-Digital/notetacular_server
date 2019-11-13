defmodule Dbstore.Billing do
  use Ecto.Schema

  schema "billings" do
    field(:stripe_customer_id, :string)
    field(:stripe_currency, :string)
    
    timestamps()
    belongs_to(:users, Dbstore.User, foreign_key: :user_id)
  end
end