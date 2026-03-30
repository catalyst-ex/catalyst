defmodule Catalyst.Actions.AppendFile do
  use Catalyst.Action

  alias Catalyst.CLI
  alias Catalyst.Execution

  defstruct [:path, :content]

  @impl true
  def run(%__MODULE__{path: path, content: content}, execution \\ Execution.new()) do
    resolved_path = Execution.resolve_path(execution, path)
    CLI.info("Appending to #{Path.basename(resolved_path)}")
    File.write!(resolved_path, content, [:append])
  end
end
