defmodule Catalyst.Actions.AddAlias do
  alias Catalyst.CLI
  alias Catalyst.Execution
  alias Sourceror.Zipper

  defstruct [:key, :commands]

  def execute(%__MODULE__{} = action, execution \\ Execution.new()) do
    path = Execution.mix_file(execution)

    CLI.info("Adding alias: #{action.key}")

    patch_mix_file(path, :aliases, fn list_zipper ->
      if list_zipper do
        upsert_alias_in_list(list_zipper, action.key, action.commands)
      else
        CLI.warn("Could not find 'aliases' function in #{path}. Skipping.")
        list_zipper
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

  defp upsert_alias_in_list(list_zipper, key, new_cmds) do
    found_key_zipper =
      Sourceror.Zipper.find(list_zipper, fn
        {^key, _} -> true
        {{:__block__, _, [^key]}, _} -> true
        _ -> false
      end)

    case found_key_zipper do
      nil ->
        Sourceror.Zipper.append_child(list_zipper, {key, new_cmds})

      key_zipper ->
        val_zipper = key_zipper |> Sourceror.Zipper.down() |> Sourceror.Zipper.right()
        val_ast = Sourceror.Zipper.node(val_zipper)

        existing_cmds = extract_commands(val_ast)
        cmds_to_add = Enum.reject(new_cmds, &(&1 in existing_cmds))

        if cmds_to_add == [] do
          CLI.warn("Alias #{key} already contains requested commands, skipping.")
          list_zipper
        else
          inner_list_zipper =
            Sourceror.Zipper.find(val_zipper, fn
              list when is_list(list) -> true
              _ -> false
            end)

          if inner_list_zipper do
            Enum.reduce(cmds_to_add, inner_list_zipper, fn cmd, z ->
              Sourceror.Zipper.append_child(z, {:__block__, [], [cmd]})
            end)
          else
            new_list_ast =
              {:__block__, [],
               [
                 [val_ast | Enum.map(cmds_to_add, fn cmd -> {:__block__, [], [cmd]} end)]
               ]}

            Sourceror.Zipper.replace(val_zipper, new_list_ast)
          end
        end
    end
  end

  defp extract_commands(ast) do
    {_, acc} =
      Macro.prewalk(ast, [], fn
        str, acc when is_binary(str) -> {str, [str | acc]}
        node, acc -> {node, acc}
      end)

    Enum.reverse(acc)
  end
end
