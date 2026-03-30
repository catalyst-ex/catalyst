defmodule Catalyst.Actions.MoveFile do
  use Catalyst.Action

  alias Catalyst.CLI

  defstruct [:from, :to]

  @impl true
  def run(%__MODULE__{from: from, to: to}, _execution) do
    CLI.info("Moving file from #{from} to #{to}")
    File.mkdir_p!(Path.dirname(to))
    File.rename(from, to)
  end
end
