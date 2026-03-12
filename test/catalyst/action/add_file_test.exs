defmodule Catalyst.Action.AddFileTest do
  use ExUnit.Case, async: true

  alias Catalyst.Action

  test "AddFile exposes expected keys" do
    expected_keys = [:__struct__, :content, :path, :template_path] |> Enum.sort()
    actual_keys = Action.AddFile.__struct__() |> Map.keys() |> Enum.sort()

    assert actual_keys == expected_keys
  end

  test "AddFile can be instantiated" do
    action =
      struct(Action.AddFile,
        path: "lib/example.ex",
        content: "example content",
        template_path: "templates/example.eex"
      )

    assert %Action.AddFile{} = action
    assert action.path == "lib/example.ex"
    assert action.content == "example content"
    assert action.template_path == "templates/example.eex"
  end
end