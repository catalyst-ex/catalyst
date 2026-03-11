defmodule Catalyst.Action.Executor do
  alias Catalyst.Action
  alias Catalyst.CLI
  alias Sourceror.Zipper

  @doc """
  Dispatches the action to the correct handler.
  """
  def run(%Action.SystemCommand{} = action), do: handle_system_command(action)
  def run(%Action.AddFile{} = action), do: handle_add_file(action)
  def run(%Action.MixTask{} = action), do: handle_mix_task(action)
  def run(%Action.AppendFile{} = action), do: handle_append_file(action)
  def run(%Action.AddAlias{} = action), do: handle_add_alias(action)
  def run(%Action.AddDependency{} = action), do: handle_add_dependency(action)
  def run(%Action.DeleteFile{} = action), do: handle_delete_file(action)
  def run(%Action.MoveFile{} = action), do: handle_move_file(action)
  def run(%Action.Function{} = action), do: handle_function(action)
  def run(%Action.AddConfig{} = action), do: handle_add_config(action)
  # Fallback for unknown actions
  def run(action) do
    CLI.warn("Unknown action encountered: #{inspect(action)}")
    {:error, :unknown_action}
  end

  # --- Handlers ---

  defp handle_system_command(%Action.SystemCommand{cmd: cmd, args: args, env: env, cd: cd}) do
    args = args || []
    env = env || []
    opts = [stderr_to_stdout: true, env: env]
    opts = if cd, do: Keyword.put(opts, :cd, cd), else: opts

    CLI.info("Running: #{cmd} #{Enum.join(args, " ")}")

    case System.cmd(cmd, args, opts) do
      {output, 0} ->
        CLI.debug(output)
        :ok

      {error, code} ->
        if allow_nonzero_exit?(cmd, args, error) do
          CLI.warn(
            "Command exited with code #{code} but was allowed: #{cmd} #{Enum.join(args, " ")}"
          )

          CLI.debug(error)
          :ok
        else
          raise "Command failed with code #{code}:\n\n #{error}"
        end
    end
  end

  defp handle_mix_task(%Action.MixTask{name: task, args: args, env: env}) do
    # Reuse SystemCommand logic to run mix tasks in a separate process
    # This prevents the Mix environment of Catalyst from polluting the target app
    handle_system_command(%Action.SystemCommand{
      cmd: "mix",
      args: [task | args || []],
      env: env
    })
  end

  defp handle_add_file(%Action.AddFile{path: path, content: content}) do
    CLI.info("Creating file: #{path}")

    dir = Path.dirname(path)
    File.mkdir_p!(dir)
    File.write!(path, content)
  end

  defp handle_append_file(%Action.AppendFile{path: path, content: content}) do
    CLI.info("Appending to #{Path.basename(path)}")
    File.write!(path, content, [:append])
  end

  defp handle_add_dependency(%Action.AddDependency{target_file: path} = action) do
    CLI.info("Adding dependency: #{action.name}")

    patch_mix_file(path, :deps, fn zipper ->
      dep_entry = build_dep_ast(action.name, action.version, action.opts)

      # Check if zipper is valid before appending
      if zipper do
        Zipper.append_child(zipper, dep_entry)
      else
        CLI.warn("Could not find 'deps' function in #{path}. Skipping.")
        # Return nil/original to skip safely
        zipper
      end
    end)
  end

  defp handle_add_alias(%Action.AddAlias{target_file: path} = action) do
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

  defp handle_delete_file(%Action.DeleteFile{path: path}) do
    CLI.info("Deleting file: #{path}")
    File.rm(path)
  end

  defp handle_move_file(%Action.MoveFile{from: from, to: to}) do
    CLI.info("Moving file from #{from} to #{to}")
    File.mkdir_p!(Path.dirname(to))
    File.rename(from, to)
  end

  defp handle_function(%Action.Function{module: mod, function: fun, args: args}) do
    CLI.info("Executing function: #{mod}.#{fun}(#{Enum.map_join(args, ", ", &inspect/1)})")
    apply(mod, fun, args || [])
  end

  defp handle_add_config(%Action.AddConfig{target_file: path} = action) do
    CLI.info(
      "Configuring: #{inspect(action.app)} #{if action.module, do: inspect(action.module)}"
    )

    unless File.exists?(path), do: raise("Config file not found: #{path}")

    source = File.read!(path)
    zipper = source |> Sourceror.parse_string!() |> Sourceror.Zipper.zip()

    # Check if this exact config block already exists to prevent duplicates
    if config_exists?(zipper, action.app, action.module) do
      CLI.info("   ↳ Config already exists, skipping.")
    else
      new_ast = build_config_ast(action.app, action.module, action.opts)

      new_zipper =
        case find_import_config(zipper) do
          nil ->
            Sourceror.Zipper.append_child(zipper, new_ast)

          import_zipper ->
            Sourceror.Zipper.insert_left(import_zipper, new_ast)
        end

      new_source = new_zipper |> Sourceror.Zipper.root() |> Sourceror.to_string()
      formatted = Code.format_string!(new_source)
      File.write!(path, formatted)
    end
  end

  # --- Helpers for Config Injection ---

  defp config_exists?(zipper, app, mod) do
    # Searches the AST for an exact match of the config signature
    found =
      Sourceror.Zipper.find(zipper, fn
        {:config, _, [^app, ^mod, _]} -> true
        {:config, _, [^app, _]} when is_nil(mod) -> true
        _ -> false
      end)

    found != nil
  end

  defp find_import_config(zipper) do
    Sourceror.Zipper.find(zipper, fn
      {:import_config, _, _} -> true
      _ -> false
    end)
  end

  defp build_config_ast(app, nil, opts) do
    quote do
      config unquote(app), unquote(opts)
    end
  end

  defp build_config_ast(app, mod, opts) do
    quote do
      config unquote(app), unquote(mod), unquote(opts)
    end
  end

  # --- AST Patching Logic for Mix Files ---

  defp patch_mix_file(path, fun_name, transform_fn) do
    unless File.exists?(path), do: raise("Could not find file to patch: #{path}")

    source = File.read!(path)

    new_source =
      source
      |> Sourceror.parse_string!()
      |> Zipper.zip()
      # <--- This traverses the tree
      |> find_function_list(fun_name)
      |> case do
        nil ->
          CLI.error("Failed to find function '#{fun_name}' in #{path}")
          # Return original source if we can't find the spot
          source

        zipper ->
          zipper
          # Apply the change
          |> transform_fn.()
          |> Zipper.root()
          |> Sourceror.to_string()
      end

    # Only write if we actually changed something
    if new_source != source do
      formatted = Code.format_string!(new_source)
      File.write!(path, formatted)
    end
  end

  # Navigates: defp deps -> do block -> list
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
        # Navigate into the 'do' block to find the list
        # Path: defp -> arguments -> [do: body] -> {:do, body} -> :do -> body
        func_zipper
        # Enter args list
        |> Zipper.down()
        # Skip function head, go to [do: ...]
        |> Zipper.right()
        # Enter keyword list -> {:do, body}
        |> Zipper.down()
        # Enter tuple -> :do
        |> Zipper.down()
        # Go to 'body'
        |> Zipper.right()
        # Ensure we are looking at a list
        |> find_list_node()
    end
  end

  defp find_list_node(zipper) do
    case Zipper.node(zipper) do
      # If the body is a direct list: defp deps, do: [...]
      list when is_list(list) ->
        zipper

      # If the body is a block: defp deps do ... end
      {:__block__, _, _} ->
        # Find the first list inside the block
        Zipper.find(zipper, fn node -> is_list(node) end)

      _ ->
        nil
    end
  end

  defp build_dep_ast(name, version, opts) do
    if opts == [] do
      # 2-element tuples {name, ver} are valid AST literals
      {name, version}
    else
      # 3-element tuples MUST be wrapped in {:{}, [], [...] }
      # otherwise Elixir thinks they are function calls.
      {:{}, [], [name, version, opts]}
    end
  end

  defp build_alias_ast(key, cmds) do
    {key, cmds}
  end

  defp upsert_alias_in_list(list_zipper, key, new_cmds) do
    found_key_zipper =
      Sourceror.Zipper.find(list_zipper, fn
        # Keyword lists in AST are tuples: {:key, value}
        {^key, _} -> true
        {{:__block__, _, [^key]}, _} -> true
        _ -> false
      end)

    case found_key_zipper do
      nil ->
        # The key doesn't exist yet. Append the brand new tuple to the list.
        alias_ast = build_alias_ast(key, new_cmds)
        Sourceror.Zipper.append_child(list_zipper, alias_ast)

      key_zipper ->
        val_zipper = key_zipper |> Sourceror.Zipper.down() |> Sourceror.Zipper.right()
        val_ast = Sourceror.Zipper.node(val_zipper)

        existing_cmds = extract_commands(val_ast)

        cmds_to_add = Enum.reject(new_cmds, &(&1 in existing_cmds))

        if cmds_to_add == [] do
          list_zipper
        else
          inner_list_zipper =
            Sourceror.Zipper.find(val_zipper, fn
              list when is_list(list) -> true
              _ -> false
            end)

          if inner_list_zipper do
            Enum.reduce(cmds_to_add, inner_list_zipper, fn cmd, z ->
              cmd_ast = {:__block__, [], [cmd]}
              Sourceror.Zipper.append_child(z, cmd_ast)
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

  defp allow_nonzero_exit?("mix", ["quality" | _], output) do
    String.contains?(output, "SCAN COMPLETE")
  end

  defp allow_nonzero_exit?(_cmd, _args, _output), do: false
end
