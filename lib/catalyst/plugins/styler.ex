defmodule Catalyst.Plugins.Styler do
  use Catalyst.Plugin

  @impl true
  def run(_execution, _opts \\ []) do
    [
      %Actions.AddDependency{
        name: :styler,
        version: "~> 1.11",
        opts: [only: [:dev, :test], runtime: false]
      },
      %Actions.MixTask{name: "deps.get"}
    ]
  end

  @impl true
  def post_validate(_execution, _opts) do
    [
      %Catalyst.ValidationAction{
        action: %Actions.MixTask{name: "format", args: ["--check-formatted"]},
        required: true
      }
    ]
  end
end
