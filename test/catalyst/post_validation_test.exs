defmodule Catalyst.PostValidationTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias Catalyst.Actions
  alias Catalyst.ValidationAction

  defmodule RequiredFailurePlugin do
    use Catalyst.Plugin

    @impl true
    def run(_execution, _opts), do: []

    @impl true
    def post_validate(_execution, _opts) do
      [
        %ValidationAction{
          action: %Actions.SystemCommand{cmd: "sh", args: ["-c", "exit 1"]},
          required: true
        }
      ]
    end
  end

  defmodule OptionalFailurePlugin do
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

  defmodule OptionalFailurePluginDuplicate do
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

  defmodule ReuseExistingActionPlugin do
    use Catalyst.Plugin

    @impl true
    def run(_execution, _opts) do
      [
        %Actions.SystemCommand{
          cmd: "sh",
          args: ["-c", "test \"$REUSE_OK\" = \"1\""],
          env: [{"REUSE_OK", "1"}]
        }
      ]
    end

    @impl true
    def post_validate(_execution, _opts) do
      [
        %ValidationAction{
          # Missing env on purpose; this should still reuse the run action by command identity.
          action: %Actions.SystemCommand{cmd: "sh", args: ["-c", "test \"$REUSE_OK\" = \"1\""]},
          required: true
        }
      ]
    end
  end

  test "required post-validation failure raises" do
    config = config_with_plugins([RequiredFailurePlugin])

    assert_raise Mix.Error, ~r/Post-validation failed/, fn ->
      Catalyst.build(config)
    end
  end

  test "optional failures are summarized and execution continues" do
    config = config_with_plugins([OptionalFailurePlugin])

    output =
      capture_io(fn ->
        assert :ok == Catalyst.build(config)
      end)

    assert output =~ "Optional post-validations reported issues"
    assert output =~ "Post-validation failed"
  end

  test "cross-plugin duplicate optional validations run once and aggregate plugin sources" do
    config = config_with_plugins([OptionalFailurePlugin, OptionalFailurePluginDuplicate])

    output =
      capture_io(fn ->
        assert :ok == Catalyst.build(config)
      end)

    assert output =~ "Optional post-validations reported issues"
    assert output =~ "Catalyst.PostValidationTest.OptionalFailurePlugin"
    assert output =~ "Catalyst.PostValidationTest.OptionalFailurePluginDuplicate"

    assert output
           |> String.split("Post-validation failed")
           |> length() == 2
  end

  test "post_validate reuses existing actions when possible" do
    config = config_with_plugins([ReuseExistingActionPlugin])

    assert :ok == Catalyst.build(config)
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
