defmodule NotebooksTest do
  use ExUnit.Case
  doctest Notebooks

  test "greets the world" do
    assert Notebooks.hello() == :world
  end
end
