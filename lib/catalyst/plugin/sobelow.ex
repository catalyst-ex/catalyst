defmodule Catalyst.Plugin.Sobelow do
  use Catalyst.Plugin
  alias Catalyst.CLI

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

  @impl true
  def post_validate(opts) do
    app_path = opts[:app_path]
    strict? = Keyword.get(opts, :strict_post_validate, false)

    command = %Action.SystemCommand{cmd: "mix", args: ["sobelow", "--exit", "low"], cd: app_path}

    case Catalyst.Plugin.run_system_command(command) do
      :ok ->
        :ok

      {:error, message} ->
        message = "mix sobelow --exit low failed:\n\n #{message}"

        if strict? do
          {:error, message}
        else
          CLI.warn(
            "Sobelow post-validation reported issues but strict mode is off.\n\n#{message}"
          )

          :ok
        end
    end
  end
end
