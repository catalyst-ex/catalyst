defmodule Catalyst.Plugins.Mailer do
  use Catalyst.Plugin
  alias Catalyst.Execution

  @impl true
  def run(execution, _opts \\ []) do
    app_module_name = Execution.app_module(execution)
    app_path = Execution.app_path(execution)
    otp_app = Execution.otp_app(execution)

    mailer_module = Module.concat([app_module_name, "Mailer"])
    mailer_root = Path.join(["lib", app_path <> "_mailer"])

    template_actions =
      [
        {"layouts/default_layout.ex", "layouts/default_layout.ex"},
        {"email.ex", "email.ex"}
      ]
      |> Enum.map(fn {target_path, template_path} ->
        %Actions.AddFile{
          path: Path.join(mailer_root, target_path),
          content: read_template!(template_path, app_module_name)
        }
      end)

    [
      %Actions.AddDependency{
        name: :swoosh,
        version: "~> 1.16",
        opts: []
      },
      %Actions.AddConfig{
        module: mailer_module,
        opts: [adapter: Swoosh.Adapters.Local]
      },
      %Actions.AddConfig{
        app: :swoosh,
        module: :api_client,
        opts: false
      }
    ] ++
      template_actions ++
      [
        %Actions.AddFile{
          path: Path.join(mailer_root, "mailer.ex"),
          content: """
          defmodule #{mailer_module} do
            use Swoosh.Mailer, otp_app: #{inspect(otp_app)}

            alias #{mailer_module}.Email
          end
          """
        },
        %Actions.MixTask{name: "deps.get"}
      ]
  end

  defp read_template!(path, app_module) do
    Application.app_dir(:catalyst, ["priv", "templates", "mailer", path])
    |> File.read!()
    |> String.replace("Catalyst", app_module)
  end
end
