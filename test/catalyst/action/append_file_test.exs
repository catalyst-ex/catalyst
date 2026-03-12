defmodule Catalyst.Action.AppendFileTest do
  use ExUnit.Case, async: true

  alias Catalyst.Action

  test "AppendFile exposes expected keys" do
    expected_keys = [:__struct__, :content, :path] |> Enum.sort()
    actual_keys = Action.AppendFile.__struct__() |> Map.keys() |> Enum.sort()

    assert actual_keys == expected_keys
  end

  test "AppendFile can be instantiated" do
    action = struct(Action.AppendFile, path: "README.md", content: "\nNew line")

    assert %Action.AppendFile{} = action
    assert action.path == "README.md"
    assert action.content == "\nNew line"
  end
end
