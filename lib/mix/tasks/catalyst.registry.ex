defmodule Mix.Tasks.Catalyst.Registry do
  use Mix.Task

  @shortdoc "Generates a Catalyst plugin registry"

  @impl true
  def run(args) do
    {opts, files, invalid} = OptionParser.parse(args, strict: [out: :string])

    if invalid != [] do
      Mix.raise("Invalid options: #{inspect(invalid)}")
    end

    if files == [] do
      Mix.raise("Usage: mix catalyst.registry [--out registry.json] <plugin-file> [...]")
    end

    out_path = Keyword.get(opts, :out, "registry.json")
    registry = build_registry(files)

    out_path
    |> Path.dirname()
    |> File.mkdir_p!()

    File.write!(out_path, JSON.encode!(registry))
    Mix.shell().info("Generated Catalyst registry: #{out_path}")
  end

  defp build_registry(files) do
    project = Mix.Project.config()

    %{
      schema_version: 1,
      package: project |> Keyword.fetch!(:app) |> Atom.to_string(),
      requirement: Keyword.fetch!(project, :version),
      plugins:
        files
        |> Enum.flat_map(&plugins_from_file!/1)
        |> Enum.sort_by(fn {name, _module} -> name end)
        |> Map.new(fn {name, module} -> {name, inspect(module)} end)
    }
  end

  defp plugins_from_file!(file) do
    unless File.exists?(file) do
      Mix.raise("Plugin file not found: #{file}")
    end

    plugins =
      file
      |> Code.compile_file()
      |> Enum.map(fn {module, _bytecode} -> module end)
      |> Enum.filter(&plugin?/1)
      |> Enum.map(&{plugin_name(&1), &1})

    if plugins == [] do
      Mix.raise("Expected #{file} to define at least one Catalyst plugin")
    end

    plugins
  end

  defp plugin?(module) do
    module.module_info(:attributes)
    |> Keyword.get_values(:behaviour)
    |> List.flatten()
    |> Enum.member?(Catalyst.Plugin)
  end

  defp plugin_name(module) do
    if function_exported?(module, :name, 0) do
      module.name()
      |> normalize_declared_name!(module)
    else
      module
      |> Module.split()
      |> List.last()
    end
  end

  defp normalize_declared_name!(name, _module) when is_atom(name), do: Atom.to_string(name)
  defp normalize_declared_name!(name, _module) when is_binary(name), do: name

  defp normalize_declared_name!(name, module) do
    Mix.raise("#{inspect(module)}.name/0 must return an atom or string, got: #{inspect(name)}")
  end
end
