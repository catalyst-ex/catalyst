defmodule Catalyst.Actions.AddFile do
  alias Catalyst.CLI

  defstruct [:path, :content, :template_path]

  def execute(%__MODULE__{path: path, content: content}) do
    CLI.info("Creating file: #{path}")

    dir = Path.dirname(path)
    File.mkdir_p!(dir)
    File.write!(path, content)
  end
end
