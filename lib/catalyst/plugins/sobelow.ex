defmodule Catalyst.Plugins.Sobelow do
  use Catalyst.Plugin
  alias Catalyst.CLI

  @impl true
  def run(_execution, _opts \\ []) do
    [
      %Actions.AddDependency{
        name: :sobelow,
        version: "0.14.0",
        opts: [only: [:dev, :test], runtime: false]
      },
      %Actions.AddAlias{
        key: :quality,
        commands: ["format", "sobelow --exit low"]
      },
      %Actions.MixTask{name: "deps.get"},
      %Actions.AppendFile{
        path: ".gitignore",
        content: "\n# Sobelow Security Logs\n.sobelow"
      }
    ]
  end

  @impl true
  def post_validate(execution, opts) do
    strict? = Keyword.get(opts, :strict_post_validate, false)

    task = %Actions.MixTask{name: "sobelow", args: ["--exit", "low"]}

    case Catalyst.Plugin.run_mix_task(task, execution) do
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
