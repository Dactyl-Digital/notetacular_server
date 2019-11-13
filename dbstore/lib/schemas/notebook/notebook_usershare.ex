defmodule Dbstore.NotebookUsershare do
  use Ecto.Schema
  import Ecto.Changeset

  schema "notebook_usershares" do
    field(:user_id, :id)
    field(:notebook_id, :id)
    field(:read_only, :boolean)
    
    timestamps()
  end
  
  def changeset(notebook_usershare, params \\ %{}) do
    notebook_usershare
    |> cast(params, [:user_id, :notebook_id, :read_only])
    |> validate_required([:user_id, :notebook_id, :read_only])
  end
end
