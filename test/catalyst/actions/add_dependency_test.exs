defmodule Catalyst.Actions.AddDependencyTest do
  use Catalyst.TestSupport.ProjectCase, async: true

  @moduletag setup_project: true

  alias Catalyst.Actions.Executor
  alias Catalyst.Actions

  test "AddDependency exposes expected keys" do
    expected_keys = [:__struct__, :name, :opts, :version] |> Enum.sort()
    actual_keys = Actions.AddDependency.__struct__() |> Map.keys() |> Enum.sort()

    assert actual_keys == expected_keys
  end

  test "AddDependency can be instantiated" do
    action =
      struct(Actions.AddDependency,
        name: :plug,
        version: "~> 1.0",
        opts: [only: :dev]
      )

    assert %Actions.AddDependency{} = action
    assert action.name == :plug
    assert action.version == "~> 1.0"
    assert action.opts == [only: :dev]
  end

  test "AddDependency updates project source end to end", %{app_path: app_path} do
    execution = test_execution(app_path)

    action =
      struct(Actions.AddDependency,
        name: :plug,
        version: "~> 1.0",
        opts: [only: :dev]
      )

    Executor.run(action, execution)

    mix_exs = Path.join(app_path, "mix.exs")
    mix_source = File.read!(mix_exs)
    assert mix_source =~ ":plug"
    assert mix_source =~ ~s("~> 1.0")
    assert mix_source =~ ~s(only: :dev)
  end

  test "AddDependency does not duplicate dependency when applied twice", %{app_path: app_path} do
    execution = test_execution(app_path)

    action =
      struct(Actions.AddDependency,
        name: :plug,
        version: "~> 1.0",
        opts: []
      )

    Executor.run(action, execution)
    Executor.run(action, execution)

    mix_exs = Path.join(app_path, "mix.exs")
    mix_source = File.read!(mix_exs)
    assert length(Regex.scan(~r/\bplug:\s*"~> 1\.0"/, mix_source)) == 1
  end
end
