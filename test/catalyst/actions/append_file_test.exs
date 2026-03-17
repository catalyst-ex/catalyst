defmodule Catalyst.Actions.AppendFileTest do
  use ExUnit.Case, async: true

  alias Catalyst.Actions

  test "AppendFile exposes expected keys" do
    expected_keys = [:__struct__, :content, :path] |> Enum.sort()
    actual_keys = Actions.AppendFile.__struct__() |> Map.keys() |> Enum.sort()

    assert actual_keys == expected_keys
  end

  test "AppendFile can be instantiated" do
    action = struct(Actions.AppendFile, path: "README.md", content: "\nNew line")

    assert %Actions.AppendFile{} = action
    assert action.path == "README.md"
    assert action.content == "\nNew line"
  end
end
