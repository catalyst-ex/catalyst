defmodule Catalyst.Plugins.Sentry do
  use Catalyst.Plugin

  alias Catalyst.Execution

  @impl true
  def run(execution, _opts \\ []) do
    [
      # Dependency
      {Actions.AddDependency, name: :sentry, version: "~> 12.0.2"},
      {Actions.AddDependency, name: :jason, version: "~> 1.1"},
      {Actions.AddDependency, name: :hackney, version: "~> 1.8"},

      # Basic Sentry config
      {Actions.AddConfig,
       app: :sentry,
       opts: [
         environment_name: quote(do: Mix.env()),
         enable_source_code_context: true,
         root_source_code_paths: quote(do: [File.cwd!()]),
         integrations: [
           oban: [
             capture_errors: true,
             cron: [enabled: true]
           ],
           telemetry: [
             report_handler_failures: true
           ]
         ]
       ]},

      # Basic Runtime Sentry config
      {Actions.AddConfig,
       config_file: "runtime.exs",
       app: :sentry,
       opts: [
         dsn: quote(do: System.get_env("SENTRY_DSN"))
       ]},

      # Logger -> Sentry bridge
      {Actions.AddConfig,
       opts: [
         logger: [
           {:handler, :sentry_handler, Sentry.LoggerHandler,
            %{
              config: %{
                metadata: [:file, :line],
                rate_limiting: [max_events: 10, interval: 1_000],
                capture_log_messages: true,
                level: :error
              }
            }}
         ]
       ]},

      # Fetch deps
      {Actions.MixTask, name: "deps.get"}
    ]
  end
end
