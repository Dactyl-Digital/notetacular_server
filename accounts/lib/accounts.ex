defmodule Accounts do
  @moduledoc """
  Documentation for Accounts.
  """

  defdelegate signup_user(params), to: Accounts.Impl
  defdelegate retrieve_user_by_username(username), to: Accounts.Impl
end
