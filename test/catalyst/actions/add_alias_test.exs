defmodule Catalyst.Actions.AddAliasTest do
  use Catalyst.TestSupport.ProjectCase, async: true

  @moduletag setup_project: true

  import ExUnit.CaptureLog

  alias Catalyst.Actions.Executor
  alias Catalyst.Actions

  test "AddAlias action tuple exposes expected keys" do
    {mod, opts} = {Actions.AddAlias, key: :setup, commands: ["deps.get", "compile"]}
    expected_keys = [:commands, :key] |> Enum.sort()
    actual_keys = opts |> Keyword.keys() |> Enum.sort()

    assert mod == Actions.AddAlias
    assert actual_keys == expected_keys
  end

  test "AddAlias action can be represented as tuple" do
    {mod, opts} = {Actions.AddAlias, key: :setup, commands: ["deps.get", "compile"]}

    assert mod == Actions.AddAlias
    assert Keyword.fetch!(opts, :key) == :setup
    assert Keyword.fetch!(opts, :commands) == ["deps.get", "compile"]
  end

  test "AddAlias updates project source end to end", %{app_path: app_path} do
    execution = test_execution(app_path)

    action = {Actions.AddAlias, key: :quality, commands: ["format", "credo"]}

    Executor.run(action, execution)

    mix_exs = Path.join(app_path, "mix.exs")
    mix_source = File.read!(mix_exs)
    assert mix_source =~ ~s(quality: ["format", "credo"])
  end

  test "AddAlias does not duplicate commands under quality when applied twice", %{
    app_path: app_path
  } do
    execution = test_execution(app_path)

    action = {Actions.AddAlias, key: :quality, commands: ["format", "credo"]}

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

    action = {Actions.AddAlias, key: :quality, commands: ["format", "credo"]}

    Executor.run(action, execution)

    output =
      capture_log(fn ->
        Executor.run(action, execution)
      end)

    assert output =~ "Alias quality already contains requested commands, skipping."
  end

  test "AddAlias does not duplicate commands for other aliases", %{app_path: app_path} do
    execution = test_execution(app_path)

    action = {Actions.AddAlias, key: :setup, commands: ["deps.get", "compile"]}

    Executor.run(action, execution)
    Executor.run(action, execution)

    mix_exs = Path.join(app_path, "mix.exs")
    mix_source = File.read!(mix_exs)

    assert length(Regex.scan(~r/setup:\s*\[/, mix_source)) == 1
    assert length(Regex.scan(~r/"deps\.get"/, mix_source)) == 1
    assert length(Regex.scan(~r/"compile"/, mix_source)) == 1
  end
end
