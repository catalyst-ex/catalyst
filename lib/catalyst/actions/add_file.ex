defmodule Catalyst.Actions.AddFile do
  alias Catalyst.CLI

  defstruct [:path, :content, :template_path]

  @type t :: %__MODULE__{
          path: Path.t() | nil,
          content: binary() | nil,
          template_path: Path.t() | nil
        }

  def execute(%__MODULE__{path: path, content: content}) do
    CLI.info("Creating file: #{path}")

    dir = Path.dirname(path)
    File.mkdir_p!(dir)
    File.write!(path, content)
  end
end
