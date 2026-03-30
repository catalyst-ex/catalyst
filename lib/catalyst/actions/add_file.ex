defmodule Catalyst.Actions.AddFile do
  use Catalyst.Action

  alias Catalyst.CLI
  alias Catalyst.Execution

  defstruct [:path, :content, :template_path]

  @impl true
  def run(%__MODULE__{path: path, content: content}, execution \\ Execution.new()) do
    resolved_path = Execution.resolve_path(execution, path)

    CLI.info("Creating file: #{resolved_path}")

    dir = Path.dirname(resolved_path)
    File.mkdir_p!(dir)
    File.write!(resolved_path, content)
  end
end
