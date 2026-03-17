defmodule Catalyst.Actions.MoveFileTest do
  use ExUnit.Case, async: true

  alias Catalyst.Actions

  test "MoveFile exposes expected keys" do
    expected_keys = [:__struct__, :from, :to] |> Enum.sort()
    actual_keys = Actions.MoveFile.__struct__() |> Map.keys() |> Enum.sort()

    assert actual_keys == expected_keys
  end

  test "MoveFile can be instantiated" do
    action = struct(Actions.MoveFile, from: "old/path.txt", to: "new/path.txt")

    assert %Actions.MoveFile{} = action
    assert action.from == "old/path.txt"
    assert action.to == "new/path.txt"
  end
end
