defmodule Catalyst.Plugin.Sobelow do
  use Catalyst.Plugin

  @impl true
  def run(opts) do
    mix_file = Path.join(opts[:app_path], "mix.exs")

    [
      %Action.AddDependency{
        name: :sobelow,
        version: "#{opts[:sobelow] || "0.14.0"}",
        opts: [only: [:dev, :test], runtime: false],
        target_file: mix_file
      },
      %Action.AddAlias{
        key: :sobelow,
        commands: ["format --check-formatted", "sobelow --exit low"],
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
      },
      # Format the code to ensure the new alias is properly formatted before running Sobelow
      %Action.SystemCommand{
        cmd: "mix",
        args: ["format"],
        cd: opts[:app_path]
      },
      %Action.SystemCommand{
        cmd: "mix",
        args: ["sobelow"],
        cd: opts[:app_path]
      }
    ]
  end
end
