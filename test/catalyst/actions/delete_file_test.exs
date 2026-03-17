defmodule Catalyst.Actions.DeleteFileTest do
  use ExUnit.Case, async: true

  alias Catalyst.Actions

  test "DeleteFile exposes expected keys" do
    expected_keys = [:__struct__, :path] |> Enum.sort()
    actual_keys = Actions.DeleteFile.__struct__() |> Map.keys() |> Enum.sort()

    assert actual_keys == expected_keys
  end

  test "DeleteFile can be instantiated" do
    action = struct(Actions.DeleteFile, path: "tmp/to_remove.txt")

    assert %Actions.DeleteFile{} = action
    assert action.path == "tmp/to_remove.txt"
  end
end
