defmodule Catalyst.Plugins.Sentry do
  use Catalyst.Plugin
  alias Sourceror.Zipper

  @impl true
  def run(execution, _opts \\ []) do
    otp = execution.config.app.otp_app
    endpoint_path = Path.join(["lib", "#{otp}_web", "endpoint.ex"])
    web_path = Path.join(["lib", "#{otp}_web.ex"])

    [
      # Dependency
      {Actions.AddDependency, name: :sentry, version: "~> 13.2.0"},
      {Actions.AddDependency, name: :jason, version: "~> 1.1"},
      {Actions.AddDependency, name: :hackney, version: "~> 1.8"},
      {Actions.PatchFile,
       path: endpoint_path,
       target: :defmodule,
       content: "plug Sentry.PlugContext",
       position: :after,
       anchor: fn
         {:plug, _, [{:__aliases__, _, [:Plug, :Parsers]} | _]} -> true
         _ -> false
       end},
      {Actions.PatchFile,
       path: web_path,
       target: [:live_view, :quote],
       content: "on_mount Sentry.LiveViewHook",
       position: :after,
       anchor: fn
         {:use, _, [{:__aliases__, _, [:Phoenix, :LiveView]}]} ->
           true

         _ ->
           false
       end},

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
