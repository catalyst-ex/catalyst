defmodule Catalyst.Actions.MoveFile do
  alias Catalyst.CLI

  defstruct [:from, :to]

  @type t :: %__MODULE__{
          from: Path.t() | nil,
          to: Path.t() | nil
        }

  def execute(%__MODULE__{from: from, to: to}) do
    CLI.info("Moving file from #{from} to #{to}")
    File.mkdir_p!(Path.dirname(to))
    File.rename(from, to)
  end
end
