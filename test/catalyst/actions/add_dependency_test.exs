defmodule Catalyst.Actions.AddDependencyTest do
  use Catalyst.TestSupport.ProjectCase, async: true

  @moduletag setup_project: true

  alias Catalyst.Actions.Executor
  alias Catalyst.Actions

  test "AddDependency action tuple exposes expected keys" do
    {mod, opts} = {Actions.AddDependency, name: :plug, version: "~> 1.0", opts: [only: :dev]}
    expected_keys = [:name, :opts, :version] |> Enum.sort()
    actual_keys = opts |> Keyword.keys() |> Enum.sort()

    assert mod == Actions.AddDependency
    assert actual_keys == expected_keys
  end

  test "AddDependency action can be represented as tuple" do
    {mod, opts} = {Actions.AddDependency, name: :plug, version: "~> 1.0", opts: [only: :dev]}

    assert mod == Actions.AddDependency
    assert Keyword.fetch!(opts, :name) == :plug
    assert Keyword.fetch!(opts, :version) == "~> 1.0"
    assert Keyword.fetch!(opts, :opts) == [only: :dev]
  end

  test "AddDependency updates project source end to end", %{app_path: app_path} do
    execution = test_execution(app_path)

    action = {Actions.AddDependency, name: :plug, version: "~> 1.0", opts: [only: :dev]}

    Executor.run(action, execution)

    mix_exs = Path.join(app_path, "mix.exs")
    mix_source = File.read!(mix_exs)
    assert mix_source =~ ":plug"
    assert mix_source =~ ~s("~> 1.0")
    assert mix_source =~ ~s(only: :dev)
  end

  test "AddDependency does not duplicate dependency when applied twice", %{app_path: app_path} do
    execution = test_execution(app_path)

    action = {Actions.AddDependency, name: :plug, version: "~> 1.0", opts: []}

    Executor.run(action, execution)
    Executor.run(action, execution)

    mix_exs = Path.join(app_path, "mix.exs")
    mix_source = File.read!(mix_exs)
    assert length(Regex.scan(~r/\bplug:\s*"~> 1\.0"/, mix_source)) == 1
  end
end
