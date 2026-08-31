defmodule Catalyst.Actions.AddDependency do
  use Catalyst.Action

  alias Catalyst.Shell
  alias Catalyst.Errors.ActionError
  alias Catalyst.Execution
  alias Sourceror.Zipper

  @impl true
  def run(action, execution \\ Execution.new()) when is_list(action) do
    path = Execution.mix_file(execution)
    name = Keyword.fetch!(action, :name)
    version = Keyword.fetch!(action, :version)
    opts = Keyword.get(action, :opts, [])

    Shell.info("Adding dependency: #{name}")

    patch_mix_file(path, :deps, fn zipper ->
      dep_entry = build_dep_ast(name, version, opts)

      if zipper do
        if dependency_exists?(zipper, name) do
          Shell.warn("Dependency #{name} already exists, skipping.")
          zipper
        else
          Zipper.append_child(zipper, dep_entry)
        end
      else
        Shell.warn("Could not find 'deps' function in #{path}. Skipping.")
        zipper
      end
    end)
  end

  defp patch_mix_file(path, fun_name, transform_fn) do
    unless File.exists?(path) do
      raise ActionError,
        reason: :file_not_found,
        context: %{path: path, function: fun_name}
    end

    source = File.read!(path)

    new_source =
      source
      |> Sourceror.parse_string!()
      |> Zipper.zip()
      |> find_function_list(fun_name)
      |> case do
        nil ->
          Shell.error("Failed to find function '#{fun_name}' in #{path}")
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

  defp build_dep_ast(name, version, []), do: {:{}, [], [name, version]}
  defp build_dep_ast(name, version, opts), do: {:{}, [], [name, version, opts]}

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
