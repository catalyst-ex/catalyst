defmodule Catalyst.Action.FunctionTest do
  use ExUnit.Case, async: true

  alias Catalyst.Action

  test "Function exposes expected keys" do
    expected_keys = [:__struct__, :args, :function, :module] |> Enum.sort()
    actual_keys = Action.Function.__struct__() |> Map.keys() |> Enum.sort()

    assert actual_keys == expected_keys
  end

  test "Function can be instantiated" do
    action = struct(Action.Function, module: Kernel, function: :apply, args: [])

    assert %Action.Function{} = action
    assert action.module == Kernel
    assert action.function == :apply
    assert action.args == []
  end
end
