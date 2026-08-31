defmodule Catalyst.Actions.DeleteFile do
  use Catalyst.Action
  require Logger

  @impl true
  def run([path: path], _execution) do
    Logger.info("Deleting file: #{path}")
    File.rm(path)
  end
end
