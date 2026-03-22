defmodule Catalyst.Plugin.Credo do
  use Catalyst.Plugin

  @impl true
  def run(_execution, _opts \\ []) do
    [
      %Actions.AddDependency{
        name: :credo,
        version: "~> 1.7",
        opts: [only: [:dev, :test], runtime: false]
      },
      %Actions.AddAlias{
        key: :quality,
        commands: ["format", "credo"]
      },
      %Actions.AddFile{
        path: ".credo.exs",
        content: read_template!(".credo.exs")
      },
      %Actions.MixTask{name: "deps.get"}
    ]
  end

  @impl true
  def post_validate(execution, _opts) do
    task = %Actions.MixTask{name: "credo"}
    Catalyst.Plugin.run_mix_task(task, execution)
  end

  defp read_template!(filename) do
    Application.app_dir(:catalyst, ["priv", "templates", filename])
    |> File.read!()
  end
end
