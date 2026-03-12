defmodule Catalyst.Action.PatchFileTest do
  use ExUnit.Case, async: true

  alias Catalyst.Action

  test "PatchFile exposes expected keys" do
    expected_keys = [:__struct__, :ops, :path] |> Enum.sort()
    actual_keys = Action.PatchFile.__struct__() |> Map.keys() |> Enum.sort()

    assert actual_keys == expected_keys
  end

  test "PatchFile can be instantiated" do
    action = struct(Action.PatchFile, path: "mix.exs", ops: [insert: "line"])

    assert %Action.PatchFile{} = action
    assert action.path == "mix.exs"
    assert action.ops == [insert: "line"]
  end
end
