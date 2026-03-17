defmodule Catalyst.Actions.FunctionTest do
  use ExUnit.Case, async: true

  alias Catalyst.Actions

  test "Function exposes expected keys" do
    expected_keys = [:__struct__, :args, :function, :module] |> Enum.sort()
    actual_keys = Actions.Function.__struct__() |> Map.keys() |> Enum.sort()

    assert actual_keys == expected_keys
  end

  test "Function can be instantiated" do
    action = struct(Actions.Function, module: Kernel, function: :apply, args: [])

    assert %Actions.Function{} = action
    assert action.module == Kernel
    assert action.function == :apply
    assert action.args == []
  end
end
