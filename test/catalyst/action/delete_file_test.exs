defmodule Catalyst.Action.DeleteFileTest do
  use ExUnit.Case, async: true

  alias Catalyst.Action

  test "DeleteFile exposes expected keys" do
    expected_keys = [:__struct__, :path] |> Enum.sort()
    actual_keys = Action.DeleteFile.__struct__() |> Map.keys() |> Enum.sort()

    assert actual_keys == expected_keys
  end

  test "DeleteFile can be instantiated" do
    action = struct(Action.DeleteFile, path: "tmp/to_remove.txt")

    assert %Action.DeleteFile{} = action
    assert action.path == "tmp/to_remove.txt"
  end
end
