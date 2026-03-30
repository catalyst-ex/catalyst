defmodule Catalyst.Actions.DeleteFile do
  use Catalyst.Action

  alias Catalyst.CLI

  defstruct [:path]

  @impl true
  def run(%__MODULE__{path: path}, _execution) do
    CLI.info("Deleting file: #{path}")
    File.rm(path)
  end
end
