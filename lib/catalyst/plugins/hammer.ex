defmodule Catalyst.Plugins.Hammer do
  use Catalyst.Plugin
  alias Catalyst.Execution
  alias Catalyst.Errors.PluginError

  @impl true
  def run(execution, _opts \\ []) do
    module = Module.concat([Execution.app_module(execution), "RateLimiter"])

    [
      {Actions.AddDependency, name: :hammer, version: "~> 0.7.0", opts: []},
      {Actions.AddFile,
       path: "lib/rate_limit.ex",
       content: """
       defmodule #{module} do
         use Hammer,
           backend: {Hammer.Backend.ETS, [expiry_ms: 60_000 * 60, cleanup_interval_ms: 60_000]},
           rate_limit: {100, :minute}
       end
       """},
      {Actions.MixTask, name: "deps.get"}
    ]
  end

  @impl true
  def post_validate(execution, _opts) do
    [
      %Catalyst.ValidationAction{
        action:
          {Actions.Function,
           module: __MODULE__, function: :validate_rate_limiter_module!, args: [execution]},
        required: true
      }
    ]
  end

  def validate_rate_limiter_module!(execution) do
    rate_limiter_path = Execution.resolve_path(execution, "lib/rate_limit.ex")

    unless File.exists?(rate_limiter_path) do
      raise PluginError,
        reason: :rate_limiter_module_missing,
        context: %{path: rate_limiter_path},
        message: "Expected RateLimiter module file not found at #{rate_limiter_path}"
    end

    :ok
  end
end
