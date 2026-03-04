defmodule Catalyst.Plugin.Mailer do
  use Catalyst.Plugin

  @impl true
  def run(opts) do
    app_path = opts[:app_path]
    app_module = Module.concat([opts[:app_module], "Mailer"])

    [
      %Action.AddDependency{
        name: :swoosh,
        version: "~> 1.16",
        opts: [],
        target_file: Path.join(app_path, "mix.exs")
      },
      %Action.AddConfig{
        target_file: Path.join(app_path, "config/config.exs"),
        app: String.to_atom(app_path),
        module: app_module,
        opts: [adapter: Swoosh.Adapters.Local]
      },
      %Action.AddConfig{
        target_file: Path.join(app_path, "config/config.exs"),
        app: :swoosh,
        module: :api_client,
        opts: false
      },
      %Action.AddFile{
        path: Path.join([app_path, "lib", app_path, "mailer.ex"]),
        content: """
        defmodule #{app_module} do
          use Swoosh.Mailer, otp_app: :#{app_path}
        end
        """
      },
      %Action.SystemCommand{cmd: "mix", args: ["deps.get"], cd: app_path}
    ]
  end
end
