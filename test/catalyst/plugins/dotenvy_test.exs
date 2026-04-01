defmodule Catalyst.Plugins.DotenvyTest do
  use Catalyst.TestSupport.ProjectCase, async: true

  @moduletag setup_project: true

  alias Catalyst.Actions
  alias Catalyst.Actions.Executor
  alias Catalyst.Plugins.Dotenvy
  alias Catalyst.ValidationAction

  test "applies dotenvy plugin actions and injects runtime config", %{app_path: app_path} do
    execution = test_execution(app_path)
    runtime_exs = Path.join([app_path, "config", "runtime.exs"])
    File.write!(runtime_exs, "import Config\n")

    actions = Dotenvy.run(execution)

    Enum.each(actions, fn
      %Actions.MixTask{} -> :ok
      action -> Executor.run(action, execution)
    end)

    mix_source = File.read!(Path.join(app_path, "mix.exs"))
    runtime_source = File.read!(runtime_exs)

    assert mix_source =~ "dotenvy: \"1.0.0\""
    assert runtime_source =~ "import Dotenvy"
    assert runtime_source =~ ~S|source(["secrets/#{config_env()}.env", System.get_env()])|

    assert %Actions.Function{module: Dotenvy, function: :inject_runtime_config} =
             Enum.find(actions, &match?(%Actions.Function{}, &1))

    assert %Actions.MixTask{name: "deps.get"} =
             Enum.find(actions, &match?(%Actions.MixTask{}, &1))
  end

  test "does not duplicate runtime dotenvy lines when run multiple times", %{app_path: app_path} do
    execution = test_execution(app_path)
    runtime_exs = Path.join([app_path, "config", "runtime.exs"])
    File.write!(runtime_exs, "import Config\n")

    Dotenvy.inject_runtime_config(execution)
    Dotenvy.inject_runtime_config(execution)

    runtime_source = File.read!(runtime_exs)

    assert String.split(runtime_source, "import Dotenvy") |> length() == 2

    assert String.split(
             runtime_source,
             ~S|source(["secrets/#{config_env()}.env", System.get_env()])|
           )
           |> length() == 2
  end

  test "no-ops runtime config injection if runtime.exs does not exist", %{app_path: app_path} do
    execution = test_execution(app_path)
    runtime_exs = Path.join([app_path, "config", "runtime.exs"])

    File.rm(runtime_exs)
    assert :ok == Dotenvy.inject_runtime_config(execution)
    refute File.exists?(runtime_exs)
  end

  test "post_validate returns required runtime config validation action" do
    validations = Dotenvy.post_validate(test_execution("."), [])

    assert [%ValidationAction{} = validation] = validations
    assert validation.required

    assert %Actions.Function{module: Dotenvy, function: :validate_runtime_config!} =
             validation.action
  end

  test "validate_runtime_config! passes when runtime.exs has dotenvy statements", %{app_path: app_path} do
    execution = test_execution(app_path)
    runtime_exs = Path.join([app_path, "config", "runtime.exs"])

    File.write!(runtime_exs, "import Config\n")
    Dotenvy.inject_runtime_config(execution)

    assert :ok == Dotenvy.validate_runtime_config!(execution)
  end

  test "validate_runtime_config! raises when runtime.exs is missing dotenvy statements", %{app_path: app_path} do
    execution = test_execution(app_path)
    runtime_exs = Path.join([app_path, "config", "runtime.exs"])

    File.write!(runtime_exs, "import Config\n")

    assert_raise RuntimeError, "runtime.exs is missing Dotenvy import/source statements", fn ->
      Dotenvy.validate_runtime_config!(execution)
    end
  end
end
