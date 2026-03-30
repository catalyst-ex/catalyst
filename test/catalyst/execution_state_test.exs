defmodule Catalyst.ExecutionStateTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias Catalyst.ActionExecution
  alias Catalyst.Actions
  alias Catalyst.Execution
  alias Catalyst.Errors.PluginError
  alias Catalyst.ValidationAction

  defmodule ActionRecordingPlugin do
    use Catalyst.Plugin

    @impl true
    def run(_execution, _opts) do
      [
        %Actions.Function{
          module: __MODULE__,
          function: :ok_action,
          args: []
        }
      ]
    end

    @impl true
    def post_validate(_execution, _opts), do: []

    def ok_action, do: :ok
  end

  defmodule OptionalValidationFailurePlugin do
    use Catalyst.Plugin

    @impl true
    def run(_execution, _opts), do: []

    @impl true
    def post_validate(_execution, _opts) do
      [
        %ValidationAction{
          action: %Actions.SystemCommand{cmd: "sh", args: ["-c", "exit 1"]},
          required: false
        }
      ]
    end
  end

  defmodule FailingRunPlugin do
    use Catalyst.Plugin

    @impl true
    def run(_execution, _opts), do: raise("boom in run")

    @impl true
    def post_validate(_execution, _opts), do: []
  end

  defmodule FailingPostValidatePlugin do
    use Catalyst.Plugin

    @impl true
    def run(_execution, _opts), do: []

    @impl true
    def post_validate(_execution, _opts), do: raise("boom in post_validate")
  end

  test "build keeps config and tracks successful plugin/action execution" do
    config = config_with_plugins([ActionRecordingPlugin])

    assert {:ok, %Execution{} = execution} = Catalyst.build(config)

    assert execution.config == config

    assert [plugin_run] = execution.plugin_runs
    assert plugin_run.plugin == ActionRecordingPlugin
    assert plugin_run.status == :ok
    assert plugin_run.actions_count == 1
    assert plugin_run.validations_count == 0

    assert [%ActionExecution{} = action_execution] = execution.action_executions
    assert action_execution.plugin == ActionRecordingPlugin
    assert action_execution.phase == :run
    assert action_execution.status == :ok
    assert match?(%Actions.Function{}, action_execution.action)
  end

  test "optional post-validation failures are tracked in action_executions" do
    config = config_with_plugins([OptionalValidationFailurePlugin])

    output =
      capture_io(fn ->
        assert {:ok, %Execution{} = execution} = Catalyst.build(config)

        assert [plugin_run] = execution.plugin_runs
        assert plugin_run.plugin == OptionalValidationFailurePlugin
        assert plugin_run.status == :ok

        assert [%ActionExecution{} = action_execution] = execution.action_executions
        assert action_execution.phase == :post_validate
        assert action_execution.required == false
        assert action_execution.status == :error
        assert action_execution.error =~ "Command failed with code 1"
      end)

    assert output =~ "Optional post-validations reported issues"
  end

  test "plugin run failures include explicit plugin_run record" do
    config = config_with_plugins([FailingRunPlugin])

    error =
      assert_raise PluginError, fn ->
        Catalyst.build(config)
      end

    assert error.reason == :plugin_execution_failed
    assert error.context.plugin_run.plugin == FailingRunPlugin
    assert error.context.plugin_run.status == :error
    assert error.context.plugin_run.actions_count == 0
    assert error.context.plugin_run.validations_count == 0
    assert error.context.plugin_run.error =~ "boom in run"
  end

  test "plugin post_validate failures include explicit plugin_run record" do
    config = config_with_plugins([FailingPostValidatePlugin])

    error =
      assert_raise PluginError, fn ->
        Catalyst.build(config)
      end

    assert error.reason == :plugin_execution_failed
    assert error.context.plugin_run.plugin == FailingPostValidatePlugin
    assert error.context.plugin_run.status == :error
    assert error.context.plugin_run.actions_count == 0
    assert error.context.plugin_run.validations_count == 0
    assert error.context.plugin_run.error =~ "boom in post_validate"
  end

  defp config_with_plugins(plugins) do
    %{
      app: %{
        path: ".",
        name: "tmp",
        module: "Tmp",
        otp_app: :tmp
      },
      mode: :new,
      plugins: plugins
    }
  end
end
