defmodule Dbstore.Membership do
  use Ecto.Schema
  import Ecto.Changeset

  schema "memberships" do
    field(:subscribed_until, :date)
    # TODO: Will it be helpful to add the plan which a user has subscribed to here?
    # plans are created in the Stripe dashboard.. So my initial thought is, no.
    
    timestamps()
    belongs_to(:users, Dbstore.User, foreign_key: :user_id)
  end
  
  def changeset(membership, params \\ %{}) do
    membership
    |> cast(params, [:subscribed_until])
    |> validate_required([:subscribed_until])
  end
end

