defmodule Catalyst.Actions.DeleteFile do
  alias Catalyst.CLI

  defstruct [:path]

  def execute(%__MODULE__{path: path}) do
    CLI.info("Deleting file: #{path}")
    File.rm(path)
  end
end
