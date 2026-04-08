defmodule Catalyst.Actions.MoveFile do
  use Catalyst.Action

  alias Catalyst.CLI

  @impl true
  def run([from: from, to: to], _execution) do
    CLI.info("Moving file from #{from} to #{to}")
    File.mkdir_p!(Path.dirname(to))
    File.rename(from, to)
  end
end
