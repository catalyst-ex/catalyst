defmodule Catalyst.Plugins.StylerTest do
  use Catalyst.TestSupport.ProjectCase, async: true

  @moduletag setup_project: true

  alias Catalyst.Actions
  alias Catalyst.Actions.Executor
  alias Catalyst.Plugins.Styler
  alias Catalyst.ValidationAction

  test "applies styler plugin actions end to end", %{app_path: app_path} do
    execution = test_execution(app_path)

    actions =
      execution
      |> Styler.run()

    Enum.each(actions, fn action ->
      if match?({Actions.MixTask, _}, action) do
        :ok
      else
        Executor.run(action, execution)
      end
    end)

    mix_source = File.read!(Path.join(app_path, "mix.exs"))

    assert mix_source =~ ~s({:styler, "~> 1.11", only: [:dev, :test], runtime: false})

    assert {Actions.MixTask, deps_opts} = Enum.find(actions, &match?({Actions.MixTask, _}, &1))
    assert Keyword.get(deps_opts, :name) == "deps.get"
  end

  test "post_validate returns required formatting validation action" do
    validations = Styler.post_validate(test_execution("."), [])

    assert [%ValidationAction{} = validation] = validations
    assert validation.required
    assert {Actions.MixTask, validation_opts} = validation.action
    assert Keyword.get(validation_opts, :name) == "format"
    assert Keyword.get(validation_opts, :args) == ["--check-formatted"]
  end
end
