defmodule Dbstore.Ecto.Types.TSVectorType do
  @behaviour Ecto.Type

  def type, do: :tsvector

  def cast(text) do
    {:ok, result} = Dbstore.Repo.query("SELECT to_tsvector('english', $1)", [text])
    {:ok, Enum.at(result.rows, 0) |> Enum.at(0)}
  end

  def load(tsvector) do
    {:ok, tsvector}
  end

  # dump/1 is a guard clause,
  # but it would appear that it only is executed upon attempting
  # to persist an update to the resource in the DB.
  # Well, this appear to be a concise explanation of cast and dump:
  # https://elixirforum.com/t/what-is-the-difference-between-ecto-types-cast-and-dump/4855/3
  def dump(tsvector), do: {:ok, tsvector}

  # Probably would need to create a custom guard in order to
  # ensure only %Postgres.Lexeme{} maps are being persisted to the DB by Ecto.
  # def dump(string) when is_binary(string), do: {:ok, string}
  # def dump(_), do: :error
end
