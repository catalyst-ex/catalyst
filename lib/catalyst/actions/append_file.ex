defmodule Catalyst.Actions.AppendFile do
  use Catalyst.Action
  require Logger

  alias Catalyst.Execution

  @impl true
  def run(action, execution \\ Execution.new()) do
    path = Keyword.fetch!(action, :path)
    content = Keyword.fetch!(action, :content)
    resolved_path = Execution.resolve_path(execution, path)
    Logger.info("Appending to #{Path.basename(resolved_path)}")
    File.write!(resolved_path, content, [:append])
  end
end
