defmodule Catalyst.Plugin.ElixirBaseTest do
  use ExUnit.Case, async: true
  alias Catalyst.Plugin.ElixirBase
  alias Catalyst.Action

  test "generates a standard OTP application" do
    opts = [app_path: "my_app"]

    actions = ElixirBase.run(opts) |> Catalyst.Plugin.normalize_actions()

    assert [
      %Action.SystemCommand{
        cmd: "mix",
        args: ["new", "my_app", "--sup"]
      },
      %Action.SystemCommand{
        cmd: "mix",
        args: ["deps.get"],
        cd: "my_app"
      }
    ] = actions
  end

  test "can disable supervision tree" do
    opts = [app_path: "simple_lib", sup: false]

    actions = ElixirBase.run(opts) |> Catalyst.Plugin.normalize_actions()

    # Verify --sup flag is missing
    assert [%{args: ["new", "simple_lib"]}, _] = actions
  end
end
