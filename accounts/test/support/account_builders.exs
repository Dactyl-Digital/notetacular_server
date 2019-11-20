# NOTE: Emulated from Designing Elixir Systems - pg 89 of 218
defmodule AccountBuilders do
  defmacro __using__(_options) do
    quote do
      alias Account
      import AccountBuilders, only: :functions
    end
  end

  alias Account
  alias Dbstore.{Repo, User, Credential, Membership, Billing}

  # ********************
  # User Setup Functions
  # ********************
  def create_user_data(i) do
    %{email: "user#{i}@test.com", username: "user#{i}", password: "password#{i}"}
  end

  def create_n_user_data(n), do: Enum.map(1..n, fn i -> create_user_data(i) end)
end
