defmodule Accounts do
  @moduledoc """
  Documentation for Accounts.
  """

  defdelegate signup_user(params), to: Accounts.Impl
end
