defmodule Catalyst.Plugins.Nebulex do
  use Catalyst.Plugin
  alias Catalyst.Actions, as: Action
  alias Catalyst.Execution

  @impl true
  def run(execution, _opts \\ []) do
    otp = Execution.otp_app(execution)
    cache_module = Module.concat(["Utils", "Cache", "Coherent"])
    application_path = Path.join(["lib", "#{otp}", "application.ex"])

    [
      {Actions.AddDependency, name: :nebulex, version: "~> 3.0"},
      {Actions.AddDependency, name: :nebulex_distributed, version: "~> 3.2"},
      {Action.AddFile,
       path: "lib/utils/cache.ex", content: File.read!(template_path("cache.ex"))},
      {Actions.PatchFile,
       path: application_path, target: {:assign, :children}, content: cache_module, position: :end},
      {Actions.AddConfig,
       module: cache_module,
       opts: [
         primary: [
           gc_interval: quote(do: :timer.hours(24)),
           max_size: 1_000_000
         ],
         stream_opts: [
           partitions: quote(do: System.schedulers_online())
         ]
       ]},
      {Actions.MixTask, name: "deps.get"}
    ]
  end

  # --- Template Helpers ---

  defp template_path(filename) do
    Application.app_dir(:catalyst, ["priv", "templates", "utils", filename])
  end
end
