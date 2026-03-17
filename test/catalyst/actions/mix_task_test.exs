defmodule Catalyst.Actions.MixTaskTest do
  use ExUnit.Case, async: true

  alias Catalyst.Actions

  test "MixTask exposes expected keys" do
    expected_keys = [:__struct__, :args, :env, :name] |> Enum.sort()
    actual_keys = Actions.MixTask.__struct__() |> Map.keys() |> Enum.sort()

    assert actual_keys == expected_keys
  end

  test "MixTask can be instantiated" do
    action =
      struct(Actions.MixTask,
        name: "deps.get",
        args: ["--only", "test"],
        env: [{"MIX_ENV", "test"}]
      )

    assert %Actions.MixTask{} = action
    assert action.name == "deps.get"
    assert action.args == ["--only", "test"]
    assert action.env == [{"MIX_ENV", "test"}]
  end
end
