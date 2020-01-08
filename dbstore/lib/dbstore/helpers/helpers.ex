defmodule Dbstore.Helpers do
  alias Ecto.Changeset

  def handle_creation_result({:ok, resource}), do: {:ok, resource}

  @doc """
    errors as it appears in the changeset as the second param to this function:
    [
      name: {"That topping name is already taken",
      [validation: :unsafe_unique, fields: [:name]]}
    ]

    errors after traverse and format_errors:
    %{name: ["That topping name is already taken"]}
  """
  def handle_creation_result({:error, changeset = %Changeset{valid?: false, errors: errors}}) do
    errors =
      changeset
      |> Changeset.traverse_errors(fn {msg, opts} ->
        # TODO: Ensure that :fields stays consistent as a way to check
        # that this opts data structure is representative of a unique_constraint.
        Keyword.has_key?(opts, :fields)
        |> format_error(msg, opts)
      end)

    {:error, errors}
  end

  # TODO: this logic (format_error) is duplicated in /accounts/lib/accounts/impl.ex
  # Perhaps move this helper error handling logic into dbstore so that
  # it may be imported here.

  # TODO: ah.... should've documented the shape of opts
  # This case handles unique_constraints
  defp format_error(true, msg, opts), do: msg

  defp format_error(false, msg, opts) do
    Enum.reduce(opts, msg, fn {key, value}, acc ->
      String.replace(acc, "%{#{key}}", to_string(value))
    end)
  end
end
