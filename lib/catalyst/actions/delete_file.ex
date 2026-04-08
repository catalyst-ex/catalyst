defmodule Catalyst.Actions.DeleteFile do
  use Catalyst.Action

  alias Catalyst.CLI

  @impl true
  def run([path: path], _execution) do
    CLI.info("Deleting file: #{path}")
    File.rm(path)
  end
end
