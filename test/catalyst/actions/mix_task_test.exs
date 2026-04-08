defmodule Catalyst.Actions.MixTaskTest do
  use ExUnit.Case, async: true

  alias Catalyst.Actions

  test "MixTask action tuple exposes expected keys" do
    {mod, opts} =
      {Actions.MixTask, name: "deps.get", args: ["--only", "test"], env: [{"MIX_ENV", "test"}]}

    expected_keys = [:args, :env, :name] |> Enum.sort()
    actual_keys = opts |> Keyword.keys() |> Enum.sort()

    assert mod == Actions.MixTask
    assert actual_keys == expected_keys
  end

  test "MixTask action can be represented as tuple" do
    {mod, opts} =
      {Actions.MixTask, name: "deps.get", args: ["--only", "test"], env: [{"MIX_ENV", "test"}]}

    assert mod == Actions.MixTask
    assert Keyword.fetch!(opts, :name) == "deps.get"
    assert Keyword.fetch!(opts, :args) == ["--only", "test"]
    assert Keyword.fetch!(opts, :env) == [{"MIX_ENV", "test"}]
  end
end
