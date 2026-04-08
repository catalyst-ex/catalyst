defmodule Catalyst.Actions.AppendFileTest do
  use ExUnit.Case, async: true

  alias Catalyst.Actions

  test "AppendFile action tuple exposes expected keys" do
    {mod, opts} = {Actions.AppendFile, path: "README.md", content: ~s(\nNew line)}
    expected_keys = [:content, :path] |> Enum.sort()
    actual_keys = opts |> Keyword.keys() |> Enum.sort()

    assert mod == Actions.AppendFile
    assert actual_keys == expected_keys
  end

  test "AppendFile action can be represented as tuple" do
    {mod, opts} = {Actions.AppendFile, path: "README.md", content: ~s(\nNew line)}

    assert mod == Actions.AppendFile
    assert Keyword.fetch!(opts, :path) == "README.md"
    assert Keyword.fetch!(opts, :content) == ~s(\nNew line)
  end
end
