defmodule Catalyst.Actions.AppendFile do
  alias Catalyst.CLI

  defstruct [:path, :content]

  def execute(%__MODULE__{path: path, content: content}) do
    CLI.info("Appending to #{Path.basename(path)}")
    File.write!(path, content, [:append])
  end
end
