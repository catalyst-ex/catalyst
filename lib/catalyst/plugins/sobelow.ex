defmodule Catalyst.Plugins.Sobelow do
  use Catalyst.Plugin

  @impl true
  def run(_execution, _opts \\ []) do
    [
      %Actions.AddDependency{
        name: :sobelow,
        version: "~> 0.14.0",
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
  def post_validate(_execution, opts) do
    strict? = Keyword.get(opts, :strict_post_validate, false)

    [
      %Catalyst.ValidationAction{
        action: %Actions.MixTask{name: "sobelow", args: ["--exit", "low"]},
        required: strict?
      }
    ]
  end
end
