defmodule Dbstore.Ecto.Types.TSVectorType do
  @behaviour Ecto.Type

  def type, do: :tsvector

  def cast(text) do
    IO.puts("THE TSVECTOR")
    IO.inspect(text)
    {:ok, result} = Dbstore.Repo.query("SELECT to_tsvector('english', $1)", [text])
    IO.puts("THE RESULT OF RAW SQL TO MAKE TSVECTOR")
    IO.inspect(Enum.at(result.rows, 0) |> Enum.at(0))
    {:ok, Enum.at(result.rows, 0) |> Enum.at(0)}
  end

  def load(tsvector), do: {:ok, tsvector}

  def dump(tsvector), do: {:ok, tsvector}
end
