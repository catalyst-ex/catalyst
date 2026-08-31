defmodule Catalyst.Actions.DeleteFile do
  use Catalyst.Action

  alias Catalyst.Shell

  @impl true
  def run([path: path], _execution) do
    Shell.info("Deleting file: #{path}")
    File.rm(path)
  end
end
