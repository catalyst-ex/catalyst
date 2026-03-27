defmodule Catalyst.Actions.AddAliasTest do
  use Catalyst.TestSupport.ProjectCase, async: true

  @moduletag setup_project: true

  import ExUnit.CaptureIO

  alias Catalyst.Actions
  alias Catalyst.Actions.Executor

  test "AddAlias exposes expected keys" do
    expected_keys = [:__struct__, :commands, :key] |> Enum.sort()
    actual_keys = Actions.AddAlias.__struct__() |> Map.keys() |> Enum.sort()

    assert actual_keys == expected_keys
  end

  test "AddAlias can be instantiated" do
    action =
      struct(Actions.AddAlias,
        key: :setup,
        commands: ["deps.get", "compile"]
      )

    assert %Actions.AddAlias{} = action
    assert action.key == :setup
    assert action.commands == ["deps.get", "compile"]
  end

  test "AddAlias updates project source end to end", %{app_path: app_path} do
    execution = test_execution(app_path)

    action =
      struct(Actions.AddAlias,
        key: :quality,
        commands: ["format", "credo"]
      )

    Executor.run(action, execution)

    mix_exs = Path.join(app_path, "mix.exs")
    mix_source = File.read!(mix_exs)
    assert mix_source =~ "quality: [\"format\", \"credo\"]"
  end

  test "AddAlias does not duplicate commands under quality when applied twice", %{
    app_path: app_path
  } do
    execution = test_execution(app_path)

    action =
      struct(Actions.AddAlias,
        key: :quality,
        commands: ["format", "credo"]
      )

    Executor.run(action, execution)
    Executor.run(action, execution)

    mix_exs = Path.join(app_path, "mix.exs")
    mix_source = File.read!(mix_exs)

    assert length(Regex.scan(~r/quality:\s*\[/, mix_source)) == 1
    assert length(Regex.scan(~r/"format"/, mix_source)) == 1
    assert length(Regex.scan(~r/"credo"/, mix_source)) == 1
  end

  test "AddAlias warns and skips when requested commands already exist", %{app_path: app_path} do
    execution = test_execution(app_path)

    action =
      struct(Actions.AddAlias,
        key: :quality,
        commands: ["format", "credo"]
      )

    Executor.run(action, execution)

    output =
      capture_io(fn ->
        Executor.run(action, execution)
      end)

    assert output =~ "warn"
    assert output =~ "Alias quality already contains requested commands, skipping."
  end

  test "AddAlias does not duplicate commands for other aliases", %{app_path: app_path} do
    execution = test_execution(app_path)

    action =
      struct(Actions.AddAlias,
        key: :setup,
        commands: ["deps.get", "compile"]
      )

    Executor.run(action, execution)
    Executor.run(action, execution)

    mix_exs = Path.join(app_path, "mix.exs")
    mix_source = File.read!(mix_exs)

    assert length(Regex.scan(~r/setup:\s*\[/, mix_source)) == 1
    assert length(Regex.scan(~r/"deps\.get"/, mix_source)) == 1
    assert length(Regex.scan(~r/"compile"/, mix_source)) == 1
  end
end
