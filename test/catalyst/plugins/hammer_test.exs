defmodule Catalyst.Plugins.HammerTest do
  use Catalyst.TestSupport.ProjectCase, async: true

  @moduletag setup_project: true

  alias Catalyst.Actions
  alias Catalyst.Actions.Executor
  alias Catalyst.Errors.PluginError
  alias Catalyst.Plugins.Hammer
  alias Catalyst.ValidationAction

  test "applies hammer plugin actions end to end", %{app_path: app_path} do
    execution = test_execution(app_path)

    actions = Hammer.run(execution)

    Enum.each(actions, fn
      %Actions.MixTask{} -> :ok
      action -> Executor.run(action, execution)
    end)

    mix_source = File.read!(Path.join(app_path, "mix.exs"))
    rate_limiter_source = File.read!(Path.join([app_path, "lib", "rate_limit.ex"]))

    assert mix_source =~ ~s(hammer: "~> 0.7.0")
    assert rate_limiter_source =~ "defmodule Elixir.Tmp.RateLimiter do"
    assert rate_limiter_source =~ "use Hammer"
    assert rate_limiter_source =~ "rate_limit: {100, :minute}"

    assert %Actions.MixTask{name: "deps.get"} =
             Enum.find(actions, &match?(%Actions.MixTask{}, &1))
  end

  test "post_validate returns required rate limiter validation action", %{app_path: app_path} do
    execution = test_execution(app_path)

    validations = Hammer.post_validate(execution, [])

    assert [%ValidationAction{} = validation] = validations
    assert validation.required

    assert %Actions.Function{
             module: Hammer,
             function: :validate_rate_limiter_module!,
             args: [^execution]
           } = validation.action
  end

  test "validate_rate_limiter_module! passes when generated file exists", %{app_path: app_path} do
    execution = test_execution(app_path)

    Executor.run(
      %Actions.AddFile{
        path: "lib/rate_limit.ex",
        content: "defmodule Tmp.RateLimiter do\nend\n"
      },
      execution
    )

    assert :ok == Hammer.validate_rate_limiter_module!(execution)
  end

  test "validate_rate_limiter_module! raises when generated file is missing", %{
    app_path: app_path
  } do
    execution = test_execution(app_path)

    assert_raise PluginError, fn ->
      Hammer.validate_rate_limiter_module!(execution)
    end
  end
end
