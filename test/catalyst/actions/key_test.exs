defmodule Catalyst.Actions.KeyTest do
  use ExUnit.Case, async: true

  alias Catalyst.Actions

  test "normalizes tuple payload order for non-specialized action keys" do
    first =
      {Actions.AddDependency,
       name: :plug, version: "~> 1.0", opts: [runtime: false, only: [:dev, :test]]}

    second =
      {Actions.AddDependency,
       version: "~> 1.0", opts: [only: [:dev, :test], runtime: false], name: :plug}

    assert Actions.key(first) == Actions.key(second)
  end
end
