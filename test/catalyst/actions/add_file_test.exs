defmodule Catalyst.Actions.AddFileTest do
  use ExUnit.Case, async: true

  alias Catalyst.Actions

  test "AddFile exposes expected keys" do
    expected_keys = [:__struct__, :content, :path, :template_path] |> Enum.sort()
    actual_keys = Actions.AddFile.__struct__() |> Map.keys() |> Enum.sort()

    assert actual_keys == expected_keys
  end

  test "AddFile can be instantiated" do
    action =
      struct(Actions.AddFile,
        path: "lib/example.ex",
        content: "example content",
        template_path: "templates/example.eex"
      )

    assert %Actions.AddFile{} = action
    assert action.path == "lib/example.ex"
    assert action.content == "example content"
    assert action.template_path == "templates/example.eex"
  end
end
