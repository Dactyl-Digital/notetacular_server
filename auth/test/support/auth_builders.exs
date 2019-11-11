# NOTE: Emulated from Designing Elixir Systems - pg 89 of 218
defmodule AuthBuilders do
  defmacro __using__(_options) do
    quote do
      alias Auth
      import AuthBuilders, only: :functions
    end
  end
  
  alias Auth
  
  def create_user(i) do
    %{
      username: "user#{i}",
      credentials: %{
        email: "user#{i}@gmail.com",
        password: "password#{i}"
      },
      memberships: %{
        subscribed_until: Timex.now() |> Timex.shift(days: 30)
      }
    }
  end
  
  def create_n_users(n), do: Enum.map((1..n), fn i -> create_user(i) end)
end