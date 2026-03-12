defmodule Catalyst.Action.SystemCommandTest do
  use ExUnit.Case, async: true

  alias Catalyst.Action

  test "SystemCommand exposes expected keys" do
    expected_keys = [:__struct__, :args, :cd, :cmd, :env] |> Enum.sort()
    actual_keys = Action.SystemCommand.__struct__() |> Map.keys() |> Enum.sort()

    assert actual_keys == expected_keys
  end

  test "SystemCommand can be instantiated" do
    action =
      struct(Action.SystemCommand,
        cmd: "mix",
        args: ["test"],
        env: [{"MIX_ENV", "test"}],
        cd: "my_app"
      )

    assert %Action.SystemCommand{} = action
    assert action.cmd == "mix"
    assert action.args == ["test"]
    assert action.env == [{"MIX_ENV", "test"}]
    assert action.cd == "my_app"
  end
end
