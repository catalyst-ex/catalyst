defmodule Catalyst.Actions.SystemCommandTest do
  use ExUnit.Case, async: true

  alias Catalyst.Actions

  test "SystemCommand action tuple exposes expected keys" do
    {mod, opts} =
      {Actions.SystemCommand,
       cmd: "mix", args: ["test"], env: [{"MIX_ENV", "test"}], cd: "my_app"}

    expected_keys = [:args, :cd, :cmd, :env] |> Enum.sort()
    actual_keys = opts |> Keyword.keys() |> Enum.sort()

    assert mod == Actions.SystemCommand
    assert actual_keys == expected_keys
  end

  test "SystemCommand action can be represented as tuple" do
    {mod, opts} =
      {Actions.SystemCommand,
       cmd: "mix", args: ["test"], env: [{"MIX_ENV", "test"}], cd: "my_app"}

    assert mod == Actions.SystemCommand
    assert Keyword.fetch!(opts, :cmd) == "mix"
    assert Keyword.fetch!(opts, :args) == ["test"]
    assert Keyword.fetch!(opts, :env) == [{"MIX_ENV", "test"}]
    assert Keyword.fetch!(opts, :cd) == "my_app"
  end
end
