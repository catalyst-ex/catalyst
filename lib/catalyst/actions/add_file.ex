defmodule Catalyst.Actions.AddFile do
  use Catalyst.Action

  alias Catalyst.Shell
  alias Catalyst.Execution

  @impl true
  def run(action, execution \\ Execution.new()) when is_list(action) do
    path = Keyword.fetch!(action, :path)
    content = Keyword.fetch!(action, :content)
    resolved_path = Execution.resolve_path(execution, path)

    Shell.info("Creating file: #{resolved_path}")

    dir = Path.dirname(resolved_path)
    File.mkdir_p!(dir)
    File.write!(resolved_path, content)
  end
end
