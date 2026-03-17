defmodule Catalyst.Actions.DeleteFile do
  alias Catalyst.CLI

  defstruct [:path]

  @type t :: %__MODULE__{path: Path.t() | nil}

  def execute(%__MODULE__{path: path}) do
    CLI.info("Deleting file: #{path}")
    File.rm(path)
  end
end
