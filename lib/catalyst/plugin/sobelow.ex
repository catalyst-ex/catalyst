defmodule Catalyst.Plugin.Sobelow do
  use Catalyst.Plugin

  @impl true
  def run(opts) do
    mix_file = Path.join(opts[:app_path], "mix.exs")

    [
      %Action.AddDependency{
        name: :sobelow,
        version: "0.14.0",
        opts: opts[:flags],
        target_file: mix_file
      },
      %Action.AddAlias{
        key: :quality,
        commands: ["format", "sobelow --exit low"],
        target_file: mix_file
      },
      %Action.SystemCommand{
        cmd: "mix",
        args: ["deps.get"],
        cd: opts[:app_path]
      },
      %Action.AppendFile{
        path: Path.join(opts[:app_path], ".gitignore"),
        content: "\n# Sobelow Security Logs\n.sobelow"
      }
    ]
  end
end
