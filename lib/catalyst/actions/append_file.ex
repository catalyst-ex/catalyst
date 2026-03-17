defmodule Catalyst.Actions.AppendFile do
  alias Catalyst.CLI

  defstruct [:path, :content]

  @type t :: %__MODULE__{
          path: Path.t() | nil,
          content: binary() | nil
        }

  def execute(%__MODULE__{path: path, content: content}) do
    CLI.info("Appending to #{Path.basename(path)}")
    File.write!(path, content, [:append])
  end
end
