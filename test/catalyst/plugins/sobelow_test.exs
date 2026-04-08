defmodule Catalyst.Plugins.SobelowTest do
  use Catalyst.TestSupport.ProjectCase, async: true

  @moduletag setup_project: true

  alias Catalyst.Actions.Executor
  alias Catalyst.Actions
  alias Catalyst.ValidationAction
  alias Catalyst.Plugins.Sobelow

  test "applies sobelow plugin actions end to end", %{app_path: app_path} do
    execution = test_execution(app_path)
    gitignore = Path.join(app_path, ".gitignore")
    File.write!(gitignore, "_build\n")

    actions =
      execution
      |> Sobelow.run()

    Enum.each(actions, fn action ->
      if match?({Actions.MixTask, _}, action) do
        :ok
      else
        Executor.run(action, execution)
      end
    end)

    mix_exs = Path.join(app_path, "mix.exs")
    mix_source = File.read!(mix_exs)

    assert mix_source =~ ~s({:sobelow, "~> 0.14.0", only: [:dev, :test], runtime: false})
    assert mix_source =~ ~s(quality: ["format", "sobelow --exit low"])

    gitignore_source = File.read!(gitignore)
    assert gitignore_source =~ "# Sobelow Security Logs"
    assert gitignore_source =~ ".sobelow"

    assert {Actions.MixTask, deps_opts} = Enum.find(actions, &match?({Actions.MixTask, _}, &1))
    assert Keyword.get(deps_opts, :name) == "deps.get"
  end

  test "post_validate returns optional action when strict mode is off" do
    validations = Sobelow.post_validate(test_execution("."), [])

    assert [%ValidationAction{} = validation] = validations
    refute validation.required
    assert {Actions.MixTask, validation_opts} = validation.action
    assert Keyword.get(validation_opts, :name) == "sobelow"
    assert Keyword.get(validation_opts, :args) == ["--exit", "low"]
  end

  test "post_validate returns required action when strict mode is on" do
    validations = Sobelow.post_validate(test_execution("."), strict_post_validate: true)

    assert [%ValidationAction{} = validation] = validations
    assert validation.required
    assert {Actions.MixTask, validation_opts} = validation.action
    assert Keyword.get(validation_opts, :name) == "sobelow"
    assert Keyword.get(validation_opts, :args) == ["--exit", "low"]
  end
end
