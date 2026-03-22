defmodule Catalyst.Actions.AddDependency do
  alias Catalyst.CLI
  alias Catalyst.Execution
  alias Sourceror.Zipper

  defstruct [:name, :version, :opts]

  def execute(%__MODULE__{} = action, execution \\ Execution.new()) do
    path = Execution.mix_file(execution)

    CLI.info("Adding dependency: #{action.name}")

    patch_mix_file(path, :deps, fn zipper ->
      dep_entry = build_dep_ast(action.name, action.version, action.opts)

      if zipper do
        if dependency_exists?(zipper, action.name) do
          CLI.warn("Dependency #{action.name} already exists, skipping.")
          zipper
        else
          Zipper.append_child(zipper, dep_entry)
        end
      else
        CLI.warn("Could not find 'deps' function in #{path}. Skipping.")
        zipper
      end
    end)
  end

  defp patch_mix_file(path, fun_name, transform_fn) do
    unless File.exists?(path), do: raise("Could not find file to patch: #{path}")

    source = File.read!(path)

    new_source =
      source
      |> Sourceror.parse_string!()
      |> Zipper.zip()
      |> find_function_list(fun_name)
      |> case do
        nil ->
          CLI.error("Failed to find function '#{fun_name}' in #{path}")
          source

        zipper ->
          zipper
          |> transform_fn.()
          |> Zipper.root()
          |> Sourceror.to_string()
      end

    if new_source != source do
      formatted = Code.format_string!(new_source)
      File.write!(path, formatted)
    end
  end

  defp find_function_list(zipper, fun_name) do
    found_func =
      Zipper.find(zipper, fn
        {type, _, [{^fun_name, _, _} | _]} when type in [:def, :defp] -> true
        _ -> false
      end)

    case found_func do
      nil ->
        nil

      func_zipper ->
        func_zipper
        |> Zipper.down()
        |> Zipper.right()
        |> Zipper.down()
        |> Zipper.down()
        |> Zipper.right()
        |> find_list_node()
    end
  end

  defp find_list_node(zipper) do
    case Zipper.node(zipper) do
      list when is_list(list) -> zipper
      {:__block__, _, _} -> Zipper.find(zipper, fn node -> is_list(node) end)
      _ -> nil
    end
  end

  defp build_dep_ast(name, version, opts) do
    if opts == [] do
      {name, version}
    else
      {:{}, [], [name, version, opts]}
    end
  end

  defp dependency_exists?(deps_list_zipper, dep_name) do
    deps_list_zipper
    |> Zipper.node()
    |> Enum.any?(&dependency_entry_matches?(&1, dep_name))
  end

  defp dependency_entry_matches?({:__block__, _, [entry]}, dep_name),
    do: dependency_entry_matches?(entry, dep_name)

  defp dependency_entry_matches?({dep_name, _}, dep_name), do: true
  defp dependency_entry_matches?({{:__block__, _, [dep_name]}, _}, dep_name), do: true
  defp dependency_entry_matches?({:{}, _, [dep_name | _]}, dep_name), do: true
  defp dependency_entry_matches?({:{}, _, [{:__block__, _, [dep_name]} | _]}, dep_name), do: true
  defp dependency_entry_matches?(_entry, _dep_name), do: false
end
