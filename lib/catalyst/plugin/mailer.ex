defmodule Catalyst.Plugin.Mailer do
  use Catalyst.Plugin
  alias Catalyst.Execution

  @impl true
  def run(execution, _opts \\ []) do
    app_module = Module.concat([execution.app_module, "Mailer"])
    app_path = execution.app_path
    otp_app = Execution.otp_app(execution)

    [
      %Actions.AddDependency{
        name: :swoosh,
        version: "~> 1.16",
        opts: []
      },
      %Actions.AddConfig{
        module: app_module,
        opts: [adapter: Swoosh.Adapters.Local]
      },
      %Actions.AddConfig{
        app: :swoosh,
        module: :api_client,
        opts: false
      },
      %Actions.AddFile{
        path: Path.join(["lib", app_path, "mailer.ex"]),
        content: """
        defmodule #{app_module} do
          use Swoosh.Mailer, otp_app: #{inspect(otp_app)}
        end
        """
      },
      %Actions.MixTask{name: "deps.get"}
    ]
  end
end
