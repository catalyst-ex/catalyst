defmodule Catalyst.Action.Executor do
  require Logger

  alias Catalyst.Action
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

  # Fallback for unknown actions
  def run(action) do
    Logger.warning("Unknown action encountered: #{inspect(action)}")
    {:error, :unknown_action}
  end

  # --- Handlers ---

  defp handle_system_command(%Action.SystemCommand{cmd: cmd, args: args, env: env, cd: cd}) do
    args = args || []
    env = env || []
    opts = [stderr_to_stdout: true, env: env]
    opts = if cd, do: Keyword.put(opts, :cd, cd), else: opts

    Logger.info("Running: #{cmd} #{Enum.join(args, " ")}")

    case System.cmd(cmd, args, opts) do
      {output, 0} ->
        Logger.debug(output)
        :ok

      {error, code} ->
        raise "Command failed with code #{code}: #{error}"
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
    Logger.info("Creating file: #{path}")

    dir = Path.dirname(path)
    File.mkdir_p!(dir)
    File.write!(path, content)
  end

  defp handle_append_file(%Action.AppendFile{path: path, content: content}) do
    Logger.info("Appending to #{Path.basename(path)}")
    File.write!(path, content, [:append])
  end

  defp handle_add_dependency(%Action.AddDependency{target_file: path} = action) do
    Logger.info("Adding dependency: #{action.name}")

    patch_mix_file(path, :deps, fn zipper ->
      dep_entry = build_dep_ast(action.name, action.version, action.opts)

      # Check if zipper is valid before appending
      if zipper do
        Zipper.append_child(zipper, dep_entry)
      else
        Logger.warning("Could not find 'deps' function in #{path}. Skipping.")
        # Return nil/original to skip safely
        zipper
      end
    end)
  end

  defp handle_add_alias(%Action.AddAlias{target_file: path} = action) do
    Logger.info("Adding alias: #{action.key}")

    patch_mix_file(path, :aliases, fn zipper ->
      alias_entry = build_alias_ast(action.key, action.commands)

      if zipper do
        Zipper.append_child(zipper, alias_entry)
      else
        Logger.warning("⚠️ Could not find 'aliases' function in #{path}. Skipping.")
        zipper
      end
    end)
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
          Logger.error("Failed to find function '#{fun_name}' in #{path}")
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
end
