defmodule Catalyst.Plugin.Quality do
  use Catalyst.Plugin

  @impl true
  def run(opts) do
    mix_file = Path.join(opts[:app_path], "mix.exs")
    flags = opts[:flags] || []

    base_actions = [
      %Action.SystemCommand{
        cmd: "mix",
        args: ["quality"],
        cd: opts[:app_path]
      }
    ]

    if "--skip-add-alias" in flags do
      base_actions
    else
      [
        %Action.AddAlias{
          key: :quality,
          commands: ["format"],
          target_file: mix_file
        }
        | base_actions
      ]
    end
  end
end
