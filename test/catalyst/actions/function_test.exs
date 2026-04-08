defmodule Catalyst.Actions.FunctionTest do
  use ExUnit.Case, async: true

  alias Catalyst.Actions

  test "Function action tuple exposes expected keys" do
    {mod, opts} = {Actions.Function, module: Kernel, function: :apply, args: []}
    expected_keys = [:args, :function, :module] |> Enum.sort()
    actual_keys = opts |> Keyword.keys() |> Enum.sort()

    assert mod == Actions.Function
    assert actual_keys == expected_keys
  end

  test "Function action can be represented as tuple" do
    {mod, opts} = {Actions.Function, module: Kernel, function: :apply, args: []}

    assert mod == Actions.Function
    assert Keyword.fetch!(opts, :module) == Kernel
    assert Keyword.fetch!(opts, :function) == :apply
    assert Keyword.fetch!(opts, :args) == []
  end
end
