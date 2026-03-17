defmodule Catalyst.Plugin.Credo do
  use Catalyst.Plugin

  @impl true
  def run(opts) do
    mix_file = Path.join(opts[:app_path], "mix.exs")

    [
      %Actions.AddDependency{
        name: :credo,
        version: "~> 1.7",
        opts: [only: [:dev, :test], runtime: false],
        target_file: mix_file
      },
      %Actions.AddAlias{
        key: :quality,
        commands: ["format", "credo"],
        target_file: mix_file
      },
      %Actions.AddFile{
        path: Path.join(opts[:app_path], ".credo.exs"),
        content: read_template!(".credo.exs")
      },
      %Actions.SystemCommand{
        cmd: "mix",
        args: ["deps.get"],
        cd: opts[:app_path]
      }
    ]
  end

  @impl true
  def post_validate(opts) do
    app_path = opts[:app_path]

    command = %Actions.SystemCommand{cmd: "mix", args: ["credo"], cd: app_path}
    Catalyst.Plugin.run_system_command(command)
  end

  defp read_template!(filename) do
    Application.app_dir(:catalyst, ["priv", "templates", filename])
    |> File.read!()
  end
end
