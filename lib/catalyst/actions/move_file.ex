defmodule Catalyst.Actions.MoveFile do
  use Catalyst.Action
  require Logger

  @impl true
  def run([from: from, to: to], _execution) do
    Logger.info("Moving file from #{from} to #{to}")
    File.mkdir_p!(Path.dirname(to))
    File.rename(from, to)
  end
end
