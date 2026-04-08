defmodule Catalyst.Plugins.CredoTest do
  use Catalyst.TestSupport.ProjectCase, async: true

  @moduletag setup_project: true

  alias Catalyst.Actions.Executor
  alias Catalyst.Actions
  alias Catalyst.ValidationAction
  alias Catalyst.Plugins.Credo

  test "applies credo plugin actions end to end", %{app_path: app_path} do
    execution = test_execution(app_path)

    actions =
      execution
      |> Credo.run()

    Enum.each(actions, fn action ->
      if match?({Actions.MixTask, _}, action) do
        :ok
      else
        Executor.run(action, execution)
      end
    end)

    mix_exs = Path.join(app_path, "mix.exs")
    mix_source = File.read!(mix_exs)

    assert File.exists?(Path.join(app_path, ".credo.exs"))
    assert mix_source =~ ~s({:credo, "~> 1.7", only: [:dev, :test], runtime: false})
    assert mix_source =~ ~s(quality: ["format", "credo"])

    assert {Actions.MixTask, deps_opts} = Enum.find(actions, &match?({Actions.MixTask, _}, &1))
    assert Keyword.get(deps_opts, :name) == "deps.get"
  end

  test "post_validate returns required credo validation action" do
    validations = Credo.post_validate(test_execution("."), [])

    assert [%ValidationAction{} = validation] = validations
    assert validation.required
    assert {Actions.MixTask, validation_opts} = validation.action
    assert Keyword.get(validation_opts, :name) == "credo"
    assert Keyword.get(validation_opts, :args) == nil
  end
end
