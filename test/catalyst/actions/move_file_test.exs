defmodule Catalyst.Actions.MoveFileTest do
  use ExUnit.Case, async: true

  alias Catalyst.Actions

  test "MoveFile action tuple exposes expected keys" do
    {mod, opts} = {Actions.MoveFile, from: "old/path.txt", to: "new/path.txt"}
    expected_keys = [:from, :to] |> Enum.sort()
    actual_keys = opts |> Keyword.keys() |> Enum.sort()

    assert mod == Actions.MoveFile
    assert actual_keys == expected_keys
  end

  test "MoveFile action can be represented as tuple" do
    {mod, opts} = {Actions.MoveFile, from: "old/path.txt", to: "new/path.txt"}

    assert mod == Actions.MoveFile
    assert Keyword.fetch!(opts, :from) == "old/path.txt"
    assert Keyword.fetch!(opts, :to) == "new/path.txt"
  end
end
