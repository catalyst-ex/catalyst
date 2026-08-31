defmodule Catalyst.Actions.MoveFile do
  use Catalyst.Action

  alias Catalyst.Shell

  @impl true
  def run([from: from, to: to], _execution) do
    Shell.info("Moving file from #{from} to #{to}")
    File.mkdir_p!(Path.dirname(to))
    File.rename(from, to)
  end
end
