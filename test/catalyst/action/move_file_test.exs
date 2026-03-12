defmodule Catalyst.Action.MoveFileTest do
  use ExUnit.Case, async: true

  alias Catalyst.Action

  test "MoveFile exposes expected keys" do
    expected_keys = [:__struct__, :from, :to] |> Enum.sort()
    actual_keys = Action.MoveFile.__struct__() |> Map.keys() |> Enum.sort()

    assert actual_keys == expected_keys
  end

  test "MoveFile can be instantiated" do
    action = struct(Action.MoveFile, from: "old/path.txt", to: "new/path.txt")

    assert %Action.MoveFile{} = action
    assert action.from == "old/path.txt"
    assert action.to == "new/path.txt"
  end
end
