defmodule Catalyst.Actions.DeleteFileTest do
  use ExUnit.Case, async: true

  alias Catalyst.Actions

  test "DeleteFile action tuple exposes expected keys" do
    {mod, opts} = {Actions.DeleteFile, path: "tmp/to_remove.txt"}
    expected_keys = [:path] |> Enum.sort()
    actual_keys = opts |> Keyword.keys() |> Enum.sort()

    assert mod == Actions.DeleteFile
    assert actual_keys == expected_keys
  end

  test "DeleteFile action can be represented as tuple" do
    {mod, opts} = {Actions.DeleteFile, path: "tmp/to_remove.txt"}

    assert mod == Actions.DeleteFile
    assert Keyword.fetch!(opts, :path) == "tmp/to_remove.txt"
  end
end
