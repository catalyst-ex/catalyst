defmodule Catalyst.Actions.AddFileTest do
  use ExUnit.Case, async: true

  alias Catalyst.Actions

  test "AddFile action tuple exposes expected keys" do
    {mod, opts} =
      {Actions.AddFile,
       path: "lib/example.ex", content: "example content", template_path: "templates/example.eex"}

    expected_keys = [:content, :path, :template_path] |> Enum.sort()
    actual_keys = opts |> Keyword.keys() |> Enum.sort()

    assert mod == Actions.AddFile
    assert actual_keys == expected_keys
  end

  test "AddFile action can be represented as tuple" do
    {mod, opts} =
      {Actions.AddFile,
       path: "lib/example.ex", content: "example content", template_path: "templates/example.eex"}

    assert mod == Actions.AddFile
    assert Keyword.fetch!(opts, :path) == "lib/example.ex"
    assert Keyword.fetch!(opts, :content) == "example content"
    assert Keyword.fetch!(opts, :template_path) == "templates/example.eex"
  end
end
