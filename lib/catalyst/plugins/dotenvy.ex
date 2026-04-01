defmodule Catalyst.Plugins.Dotenvy do
  use Catalyst.Plugin
  alias Catalyst.Execution

  @runtime_source_line ~S|source(["secrets/#{config_env()}.env", System.get_env()])|

  @impl true
  def run(execution, _opts \\ []) do
    [
      %Actions.AddDependency{
        name: :dotenvy,
        version: "1.0.0",
        opts: []
      },
      %Actions.MixTask{name: "deps.get"},
      %Actions.Function{module: __MODULE__, function: :inject_runtime_config, args: [execution]},
      %Actions.AddFile{
        path: ".env.example",
        content:
          "# Example environment variables for Dotenvy\n# DATABASE_URL=ecto://postgres:postgres@localhost/my_app_dev\n"
      }
    ]
  end

  @impl true
  def post_validate(execution, _opts) do
    [
      %Catalyst.ValidationAction{
        action: %Actions.Function{
          module: __MODULE__,
          function: :validate_runtime_config!,
          args: [execution]
        },
        required: true
      }
    ]
  end

  def validate_runtime_config!(execution) do
    runtime_path = Execution.resolve_path(execution, Path.join("config", "runtime.exs"))

    if File.exists?(runtime_path) do
      source = File.read!(runtime_path)

      unless String.contains?(source, "import Dotenvy") and
               String.contains?(source, @runtime_source_line) do
        raise "runtime.exs is missing Dotenvy import/source statements"
      end
    end

    :ok
  end

  def inject_runtime_config(execution) do
    runtime_path = Execution.resolve_path(execution, Path.join("config", "runtime.exs"))

    if File.exists?(runtime_path) do
      source = File.read!(runtime_path)

      updated_source =
        source
        |> insert_line_after("import Config", "import Dotenvy")
        |> insert_line_after("import Dotenvy", @runtime_source_line)

      if updated_source != source do
        File.write!(runtime_path, updated_source)
      end
    end

    :ok
  end

  defp insert_line_after(source, anchor_line, new_line) do
    lines = String.split(source, "\n", trim: false)

    if Enum.any?(lines, &(String.trim(&1) == new_line)) do
      source
    else
      insertion_index = Enum.find_index(lines, &(String.trim(&1) == anchor_line))

      updated_lines =
        if insertion_index do
          List.insert_at(lines, insertion_index + 1, new_line)
        else
          [new_line | lines]
        end

      Enum.join(updated_lines, "\n")
    end
  end
end
